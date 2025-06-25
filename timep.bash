#!/usr/bin/env bash

shopt -s extglob

timep() {
    ## TIME Profile - efficiently produces an accurate per-command execution time profile for shell scripts and functions using a DEBUG trap
    #
    # USAGE:     timep [-s|-f] [--] _______          --OR--
    #    [...] | timep [-s|-f] [--] _______ | [...]
    #
    # TO DO: UPDATE "OUTPUT" SECTION DOCUMENTATION. THE BELOW SECTION APPLIES TO AN OLDER VERSION OF timep
    # OUTPUT:
    #    4 types of time profiles will be saved to disk in timep's tmpdir directory (a new directory under /dev/shm or /tmp or $PWD - printed to stderr at the end):
    #        time.ALL :                       the individual per-command run times for every command run under any pid. This is generated directly by the DEBUF trap as the code runs
    #        time.<pid>.<#>_<name> :          the individual per-command run times for a specific pid at some function nesting level <#>
    #        time.combined.<pid>.<#>_<name> : the combined time and run count for each unique command run by that pid. The <#>.<#> is $SHLVL.$BASH_SUBSHELL
    #        time.combined.ALL :              the time.combined.<pid>.<#>.<#> files from all pids combined into a single file.  This is printed to stderr at the end
    #
    # OUTPUT FORMAT:
    #    for time.ALL profiles:                [ $PID.${#FUNCNAME[@]} {$NAME} ]  $LINENO:  <run_time> sec  ( <start_time --> <end_time> ) <<--- { $BASH_CMD }
    #    for time.<pid>.<#>_<name> profiles:   $LINENO:  <run_time> sec  ( <start_time --> <end_time> )  <<--- { $BASH_CMD }
    #    for time.combined profiles:           $LINENO:  <total_run_time> sec  <<--- (<run_count>x) { $BASH_CMD }
    #        NOTE: All profiles except time.ALL will list $PID and $NAME and $SHLVL.$BASH_SUBSHELL at the top of the file
    #              and will end the file with + separate data from different PIDs with a NULL.
    #
    # FLAGS:
    #    Flags must be given before the command being profiled. if multiple -s/-f are given the last one is used.
    #    -s | --shell    : force timep to treat the code being profiled as a shell script
    #    -f | --function : force timep to treat the code being profiled as a shell function
    #    --              : stop arg parsing (allows propfiling something with the same name as a flag)
    #    DEFAULT: Attempt to automatically detect shell scripts (*requires `file` for robust detection).
    #             Assume a shell function unless detection explicitly indicates a shell script.
    #
    # RUNTIME CONDITIONS/REQUIREMENTS:
    #    timep adds a several variables (all which start with "timep_") + function(s) to the runtime env of whatever is being profiled. The code being profiled must NOT modify these.
    #        FUNCTIONS:  _timep_*    trap
    #        VARIABLES:  timep_*
    #
    #    timep works by using DEBUG, EXIT and RETURN traps. To allow profiling bash code which *also* sets these traps, timep defines a `trap` funbction to overload the builtin `trap`. This function will incorporate the traps required by timep into the traps seyt by the bash code.
    #    for timep to work correctly, any EXIT/RETURN/DEBUG trapos set by the code beiung profiled must NOT be set using `builtin trap` - the overloaded `trap` function must be used (i.e., just call `trap ...`)
    #
    # DEPENDENCIES:
    #    1) bash 5.0+ (required to support the $EPOCHREALTIME variable)
    #    2) sed, grep, sort, mkdir, tail, file*
    #
    # NOTES:
    #    1. timep attempts to find the raw source code for functions being profiled, but in some instances (example: functions defined via `. <(...)` or functions defined in terminal when historyis off) this isnt possible.
    #         In these cases,  `declare -f <func>` will be treated as the source, and the line numbers may not correspond exactly to the line numbers in the original code. Commamds are, however, still ordered correctly.
    #    2. Any shell scripts called by the top-level script/function being profiled will NOT have their runtimes profiled, since the DEBUG trap doesnt propogate to sripts.
    #         To profile these, either source them (instead of calling them) or call them via `timep -s <script>`. However, shell functions that are called WILL automatically be profiled.
    #    3. To define a custom TMPDIR (other than /dev/shm/.timep.XXXXXX), pass `timep_TMPDIR` as an environment variable. e.g., timep_TMPDIR=/path/to/tmpdir timep codeToProfile
    #
    # DIFFERENCES IN HOW SCRIPTS AND FUNCTIONS ARE HANDLED
    #    If the command being profiled is a shell script, timep will create a new script file under
    #        $timep_TMPDIR that defines our DEBUG trap followed by the contents of the original script.
    #        this new script is called with any arguments passed on the timep commandline (if no flags: ${2}+).
    #    If the command being profiled is a shell function (or, in general, NOT a shell script), timep will create a new
    #        shell function (runFunc) that defines our DEBUG trap and then calls whatever commandline was passed to timep.
    #        this then gets saved to a file (main.bash) and sourced to make $LINENO give meaningful line numbers. runFunc is then called directly.
    #    The intent is to run scripts as scripts and functions as functions, so that things like $0 and $BASH_SOURCE work as expected.
    #    For both scripts and functions, if stdin is not a terminal then it is passed to the stdin of the code being profiled.
    #
    ################################################################################################################################################################

(

    shopt -s extglob
    #[[ "${SHELLOPTS}" =~ ^(.+\:)?monitor(\:.+)?$ ]] || export SHELLOPTS="${SHELLOPTS}${SHELLOPTS:+:}monitor"

    local timep_runType=''
    local -gx timep_TMPDIR

    # parse flags
    while true; do
        case "${1}" in
            -s|--shell)  timep_runType=s  ;;
            -f|--function)  timep_runType=f  ;;
            -c|--command)  timep_runType=c  ;;
            --)  shift 1 && break  ;;
             *)  break  ;;
        esac
        shift 1
    done

    # figure out where to setup a tmpdir to use (prefferably on a ramdisk/tmpfs)
    : "${timep_TMPDIR:=}"

    # try /dev/shm
    [[ -d /dev/shm ]] && {
        timep_TMPDIR=/dev/shm/.timep."$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$timep_TMPDIR" ]]; do
            timep_TMPDIR=/dev/shm/.timep."$(printf '%X' ${RANDOM}${RANDOM:1})"
        done
        mkdir -p "$timep_TMPDIR" &>/dev/null || timep_TMPDIR=''
    }

    # try /tmp
    [[ "$timep_TMPDIR" ]] || {
        timep_TMPDIR=/tmp/.timep."$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$timep_TMPDIR" ]]; do
            timep_TMPDIR=/tmp/.timep."$(printf '%X' ${RANDOM}${RANDOM:1})"
        done
        mkdir -p "$timep_TMPDIR" &>/dev/null || timep_TMPDIR=''
    }

    # try $PWD
    [[ "$timep_TMPDIR" ]] || {
        timep_TMPDIR="$PWD/.timep.$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$timep_TMPDIR" ]]; do
            timep_TMPDIR="$PWD/.timep.$(printf '%X' ${RANDOM}${RANDOM:1})"
        done
        mkdir -p "$timep_TMPDIR" &>/dev/null || timep_TMPDIR=''
    }

    # ABORT if we couldnt get a writable TMPDIR
     [[ "$timep_TMPDIR" ]] || {
         printf '\nERROR: could not create a tmpdir under /dev/shm nor /tmp nor PWD (%s). \nPlease ensure you have requisite write permissions in one of these directories. ABORTING\n\n' "${PWD}"
         return 1
    }

    mkdir -p "${timep_TMPDIR}"/.log/.endtimes

    # determine if command being profiled is a shell script or not
    if [[ "${timep_runType}" == [sfc] ]]; then
        [[ "${timep_runType}" == 's' ]] && {
            timep_runCmdPath="$(type -p "$1")"
            if [[ ${timep_runCmdPath} ]]; then
            # type -p gave a path for this command. Resolve this path if we can.
                if type realpath &>/dev/null; then
                    timep_runCmdPath="$(realpath "${timep_runCmdPath}")"
                elif type readlink &>/dev/null && [[ $(readlink "${timep_runCmdPath}") ]]; then
                    timep_runCmdPath="$(readlink "${timep_runCmdPath}")"
                fi
            fi
        }
    else
        if declare -F "$1" &>/dev/null; then
            # command is a function, which takes precedence over a script
            timep_runType=f
        else
            timep_runCmdPath="$(type -p "$1")"
            if [[ ${timep_runCmdPath} ]]; then
            # type -p gave a path for this command. Resolve this path if we can.
                if type realpath &>/dev/null; then
                    timep_runCmdPath="$(realpath "${timep_runCmdPath}")"
                elif type readlink &>/dev/null && [[ $(readlink "${timep_runCmdPath}") ]]; then
                    timep_runCmdPath="$(readlink "${timep_runCmdPath}")"
                fi

                if type file &>/dev/null && { [[ "$(file "${timep_runCmdPath}")" == *shell\ script*executable* ]] || { [[ "$(file "${timep_runCmdPath}")" == *text ]] && [[ -x "${timep_runCmdPath}" ]]; }; }; then
                    # file is text and either starts with a shebang or is executeable. Assume it is a script.
                    timep_runType=s
                elif [[ "${timep_runCmdPath}" == *.*sh ]] && read -r <"${timep_runCmdPath}" && [[ "${REPLY}" == '#!'* ]]; then
                # file name ends in .*sh (e.g., .sh or .bash) and file begins with a shebang. Assume shell script.
                    timep_runType=s
                else
                # for all other cases treat it as a shell function.
                    timep_runType=c
                fi
            else
            # type -p didnt give a path and isnt a function. Treat it as a raw command.
                timep_runType=c
            fi
        fi
    fi

# helper function to get src code from functions
_timep_getFuncSrc() {
    local out FF kk nn
    local -a F

    _timep_getFuncSrc0() {
        local m n p kk off
        local -a A

        # get where the function was sourced from. note: extdebug will tell us where thre function definition started, but not where it ends.
        read -r _ n p < <(shopt -s extdebug; declare -F "${1}")
        ((n--))

        if [[ "${p}" == 'main' ]]; then
            # try to pull function definition out of the bash history
            [[ $(history) ]] || { declare -f "${1}"; return; }
            mapfile -t off_A < <( history | grep -n '' | grep -E '^[0-9]+:[[:space:]]*[0-9]*.*((function[[:space:]]+'"${1}"')|('"${1}"'[[:space:]]*\(\)))' | sed -E s/'\:.*$'//)
            off=$(history | grep -n '' | tail -n 1 | sed -E s/'\:.*$'// )
            for kk in "${!off_A[@]}"; do
                (( off_A[$kk] = 1 + off - off_A[$kk] ))
            done
            off=$(printf '%s\n' "${off_A[@]}" | sort -n | tail -n 1)
            for kk in "${!off_A[@]}"; do
                (( off_A[$kk] = off - off_A[$kk] ))
            done            
            mapfile -t A < <(history | tail -n $off | sed -E s/'^[[:space:]]*[0-9]*[[:space:]]*'//)
        elif [[ -f "${p}" ]]; then
            # pull function definition from file
            mapfile -t A <"${p}"
            until grep -qE '^[[:space:]]*((function[[:space:]]+'"${1}"')|('"${1}"'[[:space:]]*\(\)))' <<<"${A[@]:$n:1}"; do
                ((n--))
            done
            A=("${A[@]:$n}")
            off_A=(0)
       else
            # cant extract original source. use declare -f.
            declare -f "${1}"
            return
        fi

        # return declare -f if A is empty
        (( ${#A[@]} == 0 )) && { declare -f "${1}"; return; }

        # our text blob *should* now start at the start of the function definition, but goes all the way to the EOF.
        # try sourcing just the 1st line, then the first 2, then the first 3, etc. until the function sources correctly.
        # if pulling the function definition out of the history, its possible that the text blob starts at an old definition for the function.
        #   --> also require that is produces the same `declare -f` as the orig function. if not keep going
        #  --> wrap in a 2nd function definition so that any "regular commands" wont get re-run
        funcdef0="$(declare -f "${1}")"
        validFuncDefFlag=false
        for mm in "${off_A[@]}"; do
		
		    # remove any preceeding commands on first history line
            mapfile -t -d '' cmd_rm < <(. /proc/self/fd/0 <<<"trap 'set +n; printf '\"'\"'%s\0'\"'\"' \"\${BASH_COMMAND}\"; set -n'; ${A[$mm]}" 2>/dev/null)
            for nn in "${cmd_rm[@]}"; do
                A[$mm]="${A[$mm]//"$nn"//}"
            done
			while [[ "${A[$mm]}" =~ ^[[:space:]]*\;+.*$ ]]; do 
			    A[$mm]="${A[$mm]#*\;}"
			done
			
			# find history line the function ends on by attempting to source progressively larger chunks of the history
            m=$(kk=1; IFS=$'\n'; set -n; until . /proc/self/fd/0 <<<"${A[*]:${mm}:${kk}}" &>/dev/null || (( ( mm + kk ) > ${#A[@]} )); do ((kk++)); done; echo "$kk")
			
		    # remove any trailing commands on last history line			
            (( mmm = mm + m ))
            mapfile -t -d '' cmd_rm < <(. /proc/self/fd/0 <<<"IFS=$'\n'; trap 'set +n; printf '\"'\"'%s\0'\"'\"' \"\${BASH_COMMAND}\"; set -n'; ${A[*]:${mm}:${m}}" 2>/dev/null)
            for nn in "${cmd_rm[@]}"; do
                A[$mmm]="${A[$mmm]//"$nn"//}"
            done
			while [[ "${A[$mmm]}" =~ ^.*\;+[[:space:]]*$ ]]; do 
			    A[$mmm]="${A[$mmm]%\;*}"
			done
			
			# check if recovered + isolated function definition produces the same declare -f as the original
            if ( IFS=$'\n'; . /proc/self/fd/0 <<<"unset ${1}; ${A[*]:${mm}:${m}}" &>/dev/null && [[ "$(declare -f ${1})" == "${funcdef0}" ]] ); then
                validFuncDefFlag=true
                break
            elif (( ( mm + m ) > ${#A[@]} )); then
                break
            fi
        done


        if ${validFuncDefFlag}; then
            printf '%s\n' "${A[@]:${mm}:${m}}"
        else
            declare -f "${1}"
        fi
    }

    if [[ "${timep_runType}" == 'f' ]] || declare -F "${1}" &>/dev/null || ! [[ -f "${1}" ]]; then
        out="$(_timep_getFuncSrc0 "${1}")"
    else
        out="$(<"${1}")"
    fi
    echo "$out"

    # feed the function definition through `bash --rpm-requires` to get dependencies, then test each with `type` to find function dependencies.
    # re-call _timep_getFuncSrc for each dependent function, keeping track of which function deps were already listed to avoid duplicates
    # NOTE: the "--rpm-requires" flag is non-standard, and may only be available on distros based on red hat / fedora
    : | bash --debug --rpm-requires -O extglob &>/dev/null && {
        mapfile -t F < <(bash --debug --rpm-requires -O extglob <<<"$out" | sed -E s/'^executable\((.*)\)'/'\1'/ | sort -u | while read -r nn; do type $nn 2>/dev/null | grep -qF 'is a function' && echo "$nn"; done)
        for kk in "${!F[@]}"; do
            if [[ "${FF}" == *" ${F[$kk]} "* ]]; then
                unset "F[$kk]"
            else
                FF+=" ${F[$kk]} "
            fi
        done
        for nn in "${F[@]}"; do
            FF="${FF}" _timep_getFuncSrc "${nn}"
        done
    }
}

# generate the code for a wrapper function (timep_runFunc) that wraps around whatever we are running / time profiling.
# this will setup a DEBUG trap to measure runtime from every command, then will run the specified code.
# the source code is generated and then sourced (instead of directly defined) so that things like the tmpdir/logfile path are hardcoded.
# this allows timep to run without adding any new (and potentially conflicting) variables to the code being run / time profiled.

export -p timep_RETURN_TRAP_STR &>/dev/null && export -n timep_RETURN_TRAP_STR

timep_RETURN_TRAP_STR='timep_SKIP_DEBUG_FLAG=true
unset "timep_FNEST[-1]" "timep_NEXEC_A[-1]" "timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]" "timep_NPIPE[${timep_FNEST_CUR}]" "timep_STARTTIME[${timep_FNEST_CUR}]" "timep_LINENO[${timep_FNEST_CUR}]"
timep_NEXEC_0="${timep_NEXEC_0%.*}"
timep_FUNCNAME_STR="${timep_FUNCNAME_STR%.*}"
timep_FNEST_CUR="${timep_FNEST[-1]}"
timep_SKIP_DEBUG_FLAG=false'

export -p timep_DEBUG_TRAP_STR_0 &>/dev/null && export -n timep_DEBUG_TRAP_STR_0
export -p timep_DEBUG_TRAP_STR_1 &>/dev/null && export -n timep_DEBUG_TRAP_STR_1
timep_DEBUG_TRAP_STR_0='timep_NPIPE0="${#PIPESTATUS[@]}"
timep_ENDTIME0="${EPOCHREALTIME}"
'
timep_DEBUG_TRAP_STR_1='
[[ "$-" == *m* ]] || {
  printf '"'"'\nWARNING: timep requires job control to be enabled.\n         Running "set +m" is not allowed!\n         Job control will automatically be re-enabled.\n\n'"'"' >&2
  set -m
}
[[ "${BASH_COMMAND}" == trap\ * ]] && {
  timep_SKIP_DEBUG_FLAG=true
  (( timep_FNEST_CUR == ${#FUNCNAME[@]} )) && {
    timep_FNEST_CUR="${#FUNCNAME[@]}"
    timep_FNEST+=("${#FUNCNAME[@]}")
    timep_FUNCNAME_STR+=".trap"
    timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
    timep_NEXEC_A+=("0")
    (( timep_NEXEC_N++ ))
  }
}
${timep_SKIP_DEBUG_FLAG} || {
timep_NPIPE[${timep_FNEST_CUR}]=${timep_NPIPE0}
timep_ENDTIME=${timep_ENDTIME0}
timep_IS_BG_FLAG=false
timep_IS_SUBSHELL_FLAG=false
timep_IS_FUNC_FLAG=false
if ${timep_SIMPLEFORK_NEXT_FLAG}; then
  timep_SIMPLEFORK_NEXT_FLAG=false
  timep_SIMPLEFORK_CUR_FLAG=true
else
  timep_SIMPLEFORK_CUR_FLAG=false
fi
if (( timep_BASH_SUBSHELL_PREV == BASH_SUBSHELL )); then
  if (( timep_BG_PID_PREV == $! )); then
    (( timep_FNEST_CUR >= ${#FUNCNAME[@]} )) || {
      timep_IS_FUNC_FLAG=true
      timep_NO_PRINT_FLAG=true
      timep_FNEST+=("${#FUNCNAME[@]}")
    }
  else
    timep_IS_BG_FLAG=true
  fi
else
  timep_IS_SUBSHELL_FLAG=true
  echo "${timep_ENDTIME}" >>"${timep_TMPDIR}/.log/.endtimes/${timep_NEXEC_0}.${timep_NEXEC_A[-1]}"
  (( BASHPID < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
  builtin trap '"'"':'"'"' EXIT
  IFS=\  read -r _ _ _ _ timep_CHILD_PGID _ _ timep_CHILD_TPID _ </proc/${BASHPID}/stat
  (( timep_CHILD_PGID == timep_PARENT_TPID )) || (( timep_CHILD_PGID == timep_CHILD_TPID )) || { (( timep_CHILD_PGID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )); } || timep_IS_BG_FLAG=true
fi
if ${timep_IS_SUBSHELL_FLAG} && ${timep_IS_BG_FLAG}; then
  (( timep_CHILD_PGID == BASHPID )) && (( timep_CHILD_TPID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )) && timep_SIMPLEFORK_NEXT_FLAG=true
  timep_CMD_TYPE="BACKGROUND FORK"
elif ${timep_IS_SUBSHELL_FLAG}; then
  timep_CMD_TYPE="SUBSHELL"
elif [[ "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]}" == " (F) "* ]]; then
  timep_CMD_TYPE="FUNCTION (P)"
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]# (F) }"
elif ${timep_IS_BG_FLAG}; then
  timep_CMD_TYPE="SIMPLE FORK"
elif ${timep_IS_FUNC_FLAG_1}; then
  timep_CMD_TYPE="FUNCTION (C)"
  timep_IS_FUNC_FLAG_1=false
else
  timep_CMD_TYPE="NORMAL COMMAND"
fi
if ${timep_IS_SUBSHELL_FLAG}; then
  (( timep_BASH_SUBSHELL_DIFF = BASH_SUBSHELL - timep_BASH_SUBSHELL_PREV ))
  timep_KK=0
  timep_BASHPID_ADD=()
    while (( timep_BASH_SUBSHELL_DIFF > 0 )); do
      timep_BASH_SUBSHELL_DIFF_0="${timep_BASH_SUBSHELL_DIFF}"
      (( timep_BASH_SUBSHELL_DIFF-- ))
      case "${timep_KK}" in
        0) timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}]="${BASHPID}" ;;
        *) IFS=" " read -r _ _ _ timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}] _ </proc/${timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF_0}]}/stat ;;
      esac
      if (( timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}] == timep_BASHPID_PREV )) || (( timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}] <= 1 )); then
        (( timep_BASH_SUBSHELL_DIFF++ ))
        (( timep_BASH_SUBSHELL_DIFF_0++ ))
        break
      else
        (( timep_KK++ ))
      fi
    done
    timep_KK="${timep_BASH_SUBSHELL_DIFF}"
    unset "timep_BASH_SUBSHELL_DIFF" "timep_BASH_SUBSHELL_DIFF_0"
    (( timep_NEXEC_N++ ))
    while (( timep_KK < ( ${#timep_BASHPID_ADD[@]} - 1 ) )); do
      (( timep_BASHPID_ADD[${timep_KK}] < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
      timep_BASHPID_PREV="${timep_BASHPID_ADD[${timep_KK}]}"
      timep_BASHPID_STR+=".${timep_BASHPID_PREV}"
      (( timep_KK++ ))
       timep_NEXEC_0+=".${timep_NEXEC_A[-1]}[${timep_NPIDWRAP}-${timep_BASHPID_PREV}]"
      timep_NEXEC_A+=(0)
    done
    (( timep_BASHPID_ADD[${timep_KK}] < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
    timep_BASHPID_PREV="${timep_BASHPID_ADD[${timep_KK}]}"
    unset "timep_KK" "timep_BASHPID_ADD"
    timep_LINENO[${timep_FNEST_CUR}]="${LINENO}"
    ${timep_NO_PRINT_FLAG} || printf '"'"'%s\t%s\t-\tF:%s %s\tS:%s %s\tN:%s %s.%s[%s-%s]\t%s\t::\t<< (%s) >>\n'"'"' "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_ENDTIME}"  "${timep_FNEST_CUR}" "${timep_FUNCNAME_STR}" "${BASH_SUBSHELL}" "${timep_BASHPID_STR}" "${timep_NEXEC_N}" "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_NPIDWRAP}" "${BASHPID}" "${timep_LINENO[${timep_FNEST_CUR}]}" "${timep_CMD_TYPE}" >>"${timep_TMPDIR}/.log/log.${timep_NEXEC_0}"
    timep_BASHPID_STR+=".${timep_BASHPID_PREV}"
    timep_NEXEC_0+=".${timep_NEXEC_A[-1]}[${timep_NPIDWRAP}-${timep_BASHPID_PREV}]"
    timep_NEXEC_A+=(0)
    (( timep_NEXEC_N++ ))
    timep_PARENT_PGID="$timep_CHILD_PGID"
  timep_PARENT_TPID="$timep_CHILD_TPID"
  timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
elif [[ ${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]} ]]; then
  ${timep_SIMPLEFORK_CUR_FLAG} && (( BASHPID < $! )) && {
    timep_IS_BG_FLAG=true
    timep_CMD_TYPE="SIMPLE FORK *"
  }
  if ${timep_IS_BG_FLAG}; then
     timep_IS_BG_INDICATOR='"'"'(&)'"'"'
  else
     timep_IS_BG_INDICATOR='"''"'
  fi
  [[ -s "${timep_TMPDIR}/.log/.endtimes/${timep_NEXEC_0}.${timep_NEXEC_A[-1]}" ]] && {
    {
      while read -r -u ${timep_FD} timep_ENDTIME0; do
        (( ${timep_ENDTIME0//./} < ${timep_ENDTIME//./} )) && timep_ENDTIME="${timep_ENDTIME0}"
      done
    } {timep_FD}<"${timep_TMPDIR}/.log/.endtimes/${timep_NEXEC_0}.${timep_NEXEC_A[-1]}"
    exec {timep_FD}>&-
  }
  ${timep_NO_PRINT_FLAG} || printf '"'"'%s\t%s\t%s\tF:%s %s\tS:%s %s\tN:%s %s.%s\t%s\t::\t%s %s\n'"'"' "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_STARTTIME[${timep_FNEST_CUR}]}" "${timep_ENDTIME}" "${timep_FNEST_CUR}" "${timep_FUNCNAME_STR}" "${BASH_SUBSHELL}" "${timep_BASHPID_STR}" "${timep_NEXEC_N}"  "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_LINENO[${timep_FNEST_CUR}]}" "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]@Q}" "${timep_IS_BG_INDICATOR}" >>"${timep_TMPDIR}/.log/log.${timep_NEXEC_0}"
  (( timep_NEXEC_A[-1]++ ))
  (( timep_NEXEC_N++ ))
fi
${timep_IS_FUNC_FLAG} && {
  timep_FUNCNAME_STR+=".${FUNCNAME[0]}"
  timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
  timep_NEXEC_A+=(0)
  (( timep_NEXEC_N++ ))
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]=" (F) ${BASH_COMMAND}"
  timep_LINENO[${timep_FNEST_CUR}]="${LINENO}"
  timep_NPIPE[${#FUNCNAME[@]}]="${timep_NPIPE[${timep_FNEST_CUR}]}"
  timep_FNEST_CUR="${#FUNCNAME[@]}"
  timep_NO_PRINT_FLAG=false
  timep_IS_FUNC_FLAG_1=true
}
timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${BASH_COMMAND}"
timep_LINENO[${timep_FNEST_CUR}]="${LINENO}"
timep_BG_PID_PREV="$!"
timep_BASHPID_PREV="$BASHPID"
timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"
}'

# overload the trap builtin to allow the use of custom EXIT/RETURN/DEBUG traps

export -p -f trap &>/dev/null && export -n -f trap

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap "${trapStr}"':' EXIT ;;
            RETURN)  builtin trap "${trapStr}${timep_RETURN_TRAP_STR}" RETURN ;;
            DEBUG)   builtin trap "${timep_DEBUG_TRAP_STR_0}${trapStr}${timep_DEBUG_TRAP_STR_1}" DEBUG ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
}

    { printf 'declare -gx timep_RETURN_TRAP_STR='"'"'%s'"'"'\n\ndeclare -gx timep_DEBUG_TRAP_STR_0='"'"'%s'"'"'\n\ndeclare -gx timep_DEBUG_TRAP_STR_1='"'"'%s'"'"'\n\n' "${timep_RETURN_TRAP_STR//"'"/"'"'"'"'"'"'"'"}" "${timep_DEBUG_TRAP_STR_0//"'"/"'"'"'"'"'"'"'"}" "${timep_DEBUG_TRAP_STR_1//"'"/"'"'"'"'"'"'"'"}"; declare -f trap; printf '\n\n'; } >"${timep_TMPDIR}/functions.bash"

    # setup a string with the command to run
    case "${timep_runType}" in
        s)
            shift 1
            timep_runCmd="$(<"${timep_runCmdPath}")"
            if [[ "${timep_runCmd}" == '#!'* ]]; then
                timep_runCmd1="${timep_runCmd%%$'\n'*}"
                timep_runCmd="${timep_runCmd#*$'\n'}"
            else
                timep_runCmd1='#!'"$(type -p bash)"
            fi
            # start of wrapper code
            timep_runFuncSrc="${timep_runCmd1}"$'\n'
        ;;
        c)
            printf -v timep_runCmd '%q ' ${@}
            timep_runCmd1='#!'"$(type -p bash)"

            # start of wrapper code
            timep_runFuncSrc="${timep_runCmd1}"$'\n'
        ;;
        f)
            _timep_getFuncSrc "$1" >>"${timep_TMPDIR}/functions.bash"
            timep_runCmd1='#!'"$(type -p bash)"

            printf -v timep_runCmd '%q ' ${@}
            [[ -t 0 ]] || timep_runCmd+=" <&0"

            # start of wrapper code
            timep_runFuncSrc="${timep_runCmd1}"$'\n''timep_runFunc() '
        ;;
    esac

    chmod +x "${timep_TMPDIR}/functions.bash"
timep_runFuncSrc+='(

    builtin trap - DEBUG EXIT RETURN

    declare timep_BASHPID_PREV timep_BASHPID_STR timep_BASH_SUBSHELL_PREV timep_BG_PID_PREV timep_CHILD_PGID timep_CHILD_TPID timep_CMD_TYPE timep_ENDTIME timep_ENDTIME0 timep_FD timep_FNEST_CUR timep_FUNCNAME_STR timep_IS_BG_INDICATOR timep_IS_BG_FLAG timep_IS_FUNC_FLAG timep_IS_FUNC_FLAG_1 timep_IS_SUBSHELL_FLAG EXEC_0 timep_NEXEC_N timep_NO_PRINT_FLAG timep_NPIDWRAP timep_NPIPE0 timep_PARENT_PGID timep_PARENT_TPID timep_SIMPLEFORK_CUR_FLAG timep_SIMPLEFORK_NEXT_FLAG timep_SKIP_DEBUG_FLAG timep_BASH_SUBSHELL_DIFF timep_BASH_SUBSHELL_DIFF_0 timep_KK
    declare -a timep_BASH_COMMAND_PREV timep_FNEST timep_NEXEC_A timep_NPIPE timep_STARTTIME timep_A timep_LINENO timep_BASHPID_ADD

    set -m
    set -T

    : & 2>/dev/null

    declare -gx timep_TMPDIR="'"${timep_TMPDIR}"'"
    . "${timep_TMPDIR}/functions.bash"
    export -f trap

    read -r _ _ _ _ timep_PARENT_PGID _ _ timep_PARENT_TPID _ </proc/${BASHPID}/stat
    timep_CHILD_PGID="$timep_PARENT_PGID"
    timep_CHILD_TPID="$timep_PARENT_TPID"

    timep_BASHPID_PREV="$BASHPID"
    timep_BG_PID_PREV="$!"
    timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
    timep_NEXEC_A=('"'"'0'"'"')
    timep_NPIDWRAP='"'"'0'"'"'
    timep_NEXEC_0="[${timep_NPIDWRAP}-${timep_BASHPID_PREV}]"
    timep_BASHPID_STR="${BASHPID}"
    timep_FUNCNAME_STR="main"

    timep_SIMPLEFORK_NEXT_FLAG=false
    timep_SIMPLEFORK_CUR_FLAG=false
    timep_SKIP_DEBUG_FLAG=false
    timep_NO_PRINT_FLAG=false
    timep_IS_FUNC_FLAG_1=false

    timep_FNEST=("${#FUNCNAME[@]}")
    timep_FNEST_CUR="${#FUNCNAME[@]}"

    timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]='"''"'
    timep_NPIPE[${timep_FNEST_CUR}]='"'"'0'"'"'
    timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"
    timep_LINENO[${timep_FNEST_CUR}]="${LINENO}"

    builtin trap "${timep_RETURN_TRAP_STR}" RETURN
    builtin trap '"'"':'"'"' EXIT

    echo "$(( LINENO + 4 ))" >"${timep_TMPDIR}/.log/lineno_offset"

    builtin trap "${timep_DEBUG_TRAP_STR_0}${timep_DEBUG_TRAP_STR_1}" DEBUG

    {
        '"${timep_runCmd}"'
    }  0<&${timep_FD0} 1>&${timep_FD1} 2>&${timep_FD2}

    builtin trap - DEBUG EXIT RETURN;
)'
    _timep_getFuncSrc "${timep_TMPDIR}/main.bash" >>"${timep_TMPDIR}/functions.bash"
    
    [[ "${timep_runType}" == 'f' ]] && {
        timep_runFuncSrc+=$'\n\n''timep_runFunc "${@}"'
        [[ -t 0 ]] && timep_runFuncSrc+=' <&0'
        timep_runFuncSrc+=$'\n\n'
     }


    # save script/function (with added debug trap) in new script file and make it executable
    echo "${timep_runFuncSrc}" >"${timep_TMPDIR}/main.bash"
    chmod +x "${timep_TMPDIR}/main.bash"

    printf '\\n
----------------------------------------------------------------------------
----------------------- RUNTIME BREAKDOWN BY COMMAND -----------------------
----------------------------------------------------------------------------

COMMAND PROFILED:
%s

START TIME:
%s (%s)

FORMAT (TAB-SEPERATED):
---------------------------------------------------------------------------------------------------------------------------
NPIPE    STARTTIME    ENDTIME    F:FNEST FUNCNAME_A    S:SNEST BASHPID_A    N:NEXEC_N NEXEC    LINENO    ::    BASH_COMMAND
---------------------------------------------------------------------------------------------------------------------------\\n\\n' "$([[ "${timep_runType}" == 'f' ]] && printf '%s' "${timep_runCmd}" || printf '%s' "${timep_runCmdPath}")" "$(date)" "${EPOCHREALTIME}" >"${timep_TMPDIR}/.log/format"

# attempt to figure out the controling terminal from this shell or one of its parents/grandparents/...
timep_PTY_FLAG=false
timep_PPID=${BASHPID}
until ${timep_PTY_FLAG}; do
    timep_PPID0=${timep_PPID}
    IFS=\  read -r _ _ _ timep_PPID _ <"/proc/${timep_PPID0}/stat"
    for kk in 2 0 1; do
        {
            [[ -t "${timep_PTY_FD_TEST}" ]] && { 
                timep_PTY_FLAG=true
                timep_PTY_FD="/proc/${timep_PPID}/fd/${kk}"
            }
        } {timep_PTY_FD_TEST}<>"/proc/${timep_PPID}/fd/${kk}"
        exec {timep_PTY_FD_TEST}>&-
        ${timep_PTY_FLAG} && break
    done
    (( timep_PPID > 1 )) || break
done

# if we couldnt find one in a parent try to use /dev/tty or /dev/pts/_ directly
${timep_PTY_FLAG} || {
    if [[ -e /dev/tty ]]; then
        timep_PTY_FLAG=true
        timep_PTY_FD='/dev/tty'
    elif [[ -d /dev/pts ]]; then
        for nn in /dev/pts/*; do
            [[ -O "$nn" ]] && { 
                timep_PTY_FLAG=true
                timep_PTY_FD="${nn}"
                break
            }
        done
    fi
}

${timep_PTY_FLAG} || printf '\n\nWARNING: job control could not be enabled due to lack of controlling TTY/PTY. subshells and background forks may not be properly distinguished!\n\n' >&${timep_FD2}

export timep_FD0="${timep_FD0}" 
export timep_FD1="${timep_FD1}"
export timep_FD2="${timep_FD2}"

if ${timep_PTY_FLAG}; then
    if [[ -t 0 ]]; then
        {
            "$(type -p bash)" -o monitor -O extglob "${timep_TMPDIR}/main.bash" "${@}"
        } 1>"${timep_PTY_FD}" 2>"${timep_PTY_FD}"
    else
        {
            "$(type -p bash)" -o monitor -O extglob "${timep_TMPDIR}/main.bash" "${@}"
        } 0<"${timep_PTY_FD}" 1>"${timep_PTY_FD}" 2>"${timep_PTY_FD}"

    fi
else
    if [[ -t 0 ]]; then
       "${timep_TMPDIR}/main.bash"
    else
       "${timep_TMPDIR}/main.bash" <&0
    fi
fi

printf '\n\nThe %s being time profiled has finished running!\ntimep will now process the logged timing data.\ntimep will save the time profiles it generates in "%s"\n\n' "$([[ "${timep_runType}" == 's' ]] && echo 'script' || echo 'function')" "${timep_TMPDIR}" >&2
unset IFS

#ls -la "${timep_TMPDIR}"/.log/
#find "${timep_TMPDIR}"/.log/ -empty -exec rm {} +

sleep 1
mapfile -t timep_LOG_A < <(printf '%s\n' "${timep_TMPDIR}"/.log/log* | sort -V)
for nn in "${timep_LOG_A[@]}"; do printf '\n\n------------------------------------------------------------------\n%s\n\n' "$nn"; sort -n -k2 <"$nn"; done >&2

# TO DO
##### AFTER the code has finished running, a post-processing phase will:
# 1. identify commands that are parts of pipelines by lookig for NPIPE > 1. NPIPE is greater that 1 for a single DEBUG trap firing after a pipeline has finished.
# 2. identify commands that are background forks and move them (plus trheir subtrees) into new root PID dirs under .log
# 3. starting with the most deeply nested logs, compute the total run time (by summing the individual command runtimes), then merge the log upwad into the "placeholder line" in the parent's log. use the summer runtime (not end time - start time) for this "placeholder line" so that the runtime profile is minimally affected by the timing instrumentation
:<<'EOF'
# get lists of unique commands run (unique combinations of pid + subshell level in the logged data
mapfile -t -d '' uniq_pids < <(printf '%s\0' "${timep_TMPDIR}"/time.[0-9]*)
uniq_pids=("${uniq_pids[@]##*/time.}")

#mapfile -t uniq_pids < <(grep -E '^\[ [0-9->]+ \{[^ ]*_[0-9\.]+\} \]' "${timep_TMPDIR}/time.ALL" 2>/dev/null | sed -E s/'^\[ ([0-9]+)(\-\>[0-9]+)* \{([^ ]*_[0-9\.]+)\} \] .*$'/'\1_\3'/ | sort -u)

for p in "${uniq_pids[@]}"; do
    # print header with PID and shell nesting level >"${timep_TMPDIR}/time.${p}"
    # separate out the data for each pid and save it in a file called time.<pid>
    p0="${p%%_*}"
    p1="${p#*_}"
    #grep -E '^\[ '"${p0}"' \{'"${p1}"'\} \]' "${timep_TMPDIR}/time.ALL" 2>/dev/null | sed -E s/'^\[ [0-9]+ \{[^ ]*_[0-9\.]+\} \] +'// >>"${timep_TMPDIR}/time.${p}"
    printf '\n\0' >>"${timep_TMPDIR}/time.${p}"

    # find the unique commands (pid + subshell_lvl + line number + cmd) from just this pid/subshell_lvl
    mapfile -t uniq_lines_pid < <(grep -a -v -E '^((PID)|(NAME)|(NESTING)|([0-9]+\:[[:space:]]+ERROR)|\:|\0|$)' 2>/dev/null <"${timep_TMPDIR}/time.$p" | sed -E 's/:[^<:]+<<\-\-\- /: /' | sort -u)

    tSumAll0=0
    printf -v outCur0 'NESTING LVL:\t%s\nPID:        \t%s\nNAME:        \t%s\n' "${p0##*.}" "${p0%%.*}" "${p1}"
    outCur=("${outCur0}")

    # for each unique command run by this unique command, pull out the run count and pull out the run times and sum them together
    # print a line to the time.combined.<pid> file vcontaining the run count and the combined run time for that command
    # also, keep track of total run time for this PID
    for l in "${uniq_lines_pid[@]}"; do
        [[ $l ]] || continue
        mapfile -t linesCmdCur < <(grep -a -F "${l#*:}" "${timep_TMPDIR}/time.$p" 2>/dev/null | grep -F "${l%%:*}" 2>/dev/null)
        timesCmdCur=("${linesCmdCur[@]#*:  }")
        timesCmdCur=("${timesCmdCur[@]%% sec*}")
        timesCmdCur=("${timesCmdCur[@]//./}")
        timesCmdCur=("${timesCmdCur[@]//-+(0)/-}")
        IFS='+'
        tSum0="$(( "${timesCmdCur[*]##+(0)}" ))"
        unset IFS
        (( tSumAll0+=tSum0 ))
        printf -v tSum '%.07d' "$tSum0"
        t6=$(( ${#tSum} - 6 ))
        printf -v outCur0 '%s:  %s.%s sec \t <<--- (%sx) %s\n' "${linesCmdCur[0]%%:*}" "${tSum:0:$t6}" "${tSum:$t6}" "${#timesCmdCur[@]}" "${linesCmdCur[0]#*<<\-\-\- }"
        outCur+=("${outCur0}")
    done
    printf -v tSumAll '%.07d' "$tSumAll0"
    t6=$(( ${#tSumAll} - 6 ))
    printf '%s' "${outCur[0]}" >"${timep_TMPDIR}/time.combined.$p"
    printf 'TIME:        \t%s.%s sec\nID:          \t%s {%s}\n' "${tSumAll:0:$t6}" "${tSumAll:$t6}" "${p0}" "${p1}" >>"${timep_TMPDIR}/time.combined.$p"
    printf '%s\n' "${outCur[@]:1}" | sort -g -k5 >>"${timep_TMPDIR}/time.combined.$p"
    printf '\n----------------------------------------------------------------\n\n\0' >>"${timep_TMPDIR}/time.combined.$p"
done

printf 'The following time profile is separated by context level (process ID (pid) + subshell and function nesting level + FUNCNAME)
For each line/command run in each pid, the total combined time from all evaluations (as well as the number of evaluations) is shown

FORMAT:
----------------------------------------------------------------------------
LINENO:  TOTAL_RUNTIME <<--- (COUNTx) { CMD }
----------------------------------------------------------------------------

' >"${timep_TMPDIR}"/time.combined.ALL
cat "${timep_TMPDIR}"/time.combined.[0-9]* | sort -z -k 2 | sed -z -E s/'\n{3,}'/'\n\n\n'/g >> "${timep_TMPDIR}"/time.combined.ALL
printf '\n\nAdditional time profiles, including non-combined ones that show individual command runtimes, can be found under:\n    %s\n\n' "${timep_TMPDIR}" >>"${timep_TMPDIR}"/time.combined.ALL
cat "${timep_TMPDIR}"/time.combined.ALL >&2

export -n timep_TMPDIR
export -nf _timep_printTimeDiff
export -nf _timep_check_traps

#\rm -f "${timep_TMPDIR}"/.timep.*
#if ! [[  "${timep_TMPDIR}" == "$PWD" ]] && { { shopt nullglob &>/dev/null && [[ -z $(printf '%s' "${timep_TMPDIR}"/*) ]]; } || { ! shopt nullglob &>/dev/null && [[ "$(printf '%s' "${timep_TMPDIR}"/*)" == "${timep_TMPDIR}"'/*' ]]; }; }; then
#    \rm -r "${timep_TMPDIR}"
#fi
EOF
) {timep_FD0}<&0 {timep_FD1}>&1 {timep_FD2}>&2
}
