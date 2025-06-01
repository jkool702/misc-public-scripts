#!/usr/bin/env bash

shopt -s extglob

timep() (
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

    shopt -s extglob

    local timep_runType=''
    local -a timep_DEBUG_TRAP_STR

    # parse flags
    while true; do
        case "${1}" in
            -s|--shell)  timep_runType=s  ;;
            -f|--function)  timep_runType=f  ;;
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

    export timep_TMPDIR="${timep_TMPDIR}"
    mkdir -p "${timep_TMPDIR}"/.log

    # determine if command being profiled is a shell script or not
    [[ ${timep_runType} == [sf] ]] || {
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
                    timep_runType=f
                fi
            else
            # type -p didnt give a path. Treat it as a shell function.
                timep_runType=f
            fi
        fi
    }


# helper function to get src code from functions
_timep_getFuncSrc() {
    local out

    getFuncSrc0() {
        local m n p kk off
        local -a A

        # get where the function was sourced from. note: extdebug will tell us where thre function definition started, but not where it ends.
        read -r _ n p < <(shopt -s extdebug; declare -F "${1}")
        ((n--))

        if [[ "${p}" == 'main' ]]; then
            # try to pull function definition out of the bash history
            off=$(( 1 - $( { history | grep -n '' | grep -E '^[0-9]+:[[:space:]]*[0-9]*[[:space:]]*((function[[:space:]]+'"${1}"')|('"${1}"'[[:space:]]*\(\)))' | tail -n 1; history | grep -n '' | tail -n 1; } | sed -E s/'\:.*$'// | sed -zE s/'\n'/' +'/) ))
            mapfile -t A < <(history | tail -n $off | sed -E s/'^[[:space:]]*[0-9]*[[:space:]]*'//)
        elif [[ -f "${p}" ]]; then
            # pull function definition from file
            mapfile -t A <"${p}"
            A=("${A[@]:$n}")
        else
            # cant extract original source. use declare -f.
            declare -f "${1}"
            return
        fi

        # return declare -f if A is empty
        (( ${#A[@]} == 0 )) && { declare -f "$1"; return; }

        # our text blob *should* now start at the start of the function definition, but goes all the way to the EOF.
        # try sourcing just the 1st line, then the first 2, then the first 3, etc. until the function sources correctly.
        m=$( kk=1;  IFS=$'\n'; until . /proc/self/fd/0 <<<"${A[*]:0:$kk}" &>/dev/null || (( m > ${#A[@]} )); do ((kk++)); done; echo "$kk"; )
        if (( m == 0 )) || (( m > ${#A[@]} )); then
            declare -f "$1"
        else
            printf '%s\n' "${A[@]:0:$m}"
        fi
    }

    out="$(getFuncSrc0 "$1")"
    echo "$out"

    # feed the function definition through `bash --rpm-requires` to get dependencies,
    # then test each with `type` to find function dependencies.
    # re-call _timep_getFuncSrc for each dependent function.
    bash --debug --rpm-requires -O extglob <<<"$out" | sed -E s/'^executable\((.*)\)'/'\1'/ | sort -u | while read -r nn; do type $nn 2>/dev/null | grep -qF 'is a function' && _timep_getFuncSrc "$nn"; done
}




# generate the code for a wrapper function (timep_runFunc) that wraps around whatever we are running / time profiling.
# this will setup a DEBUG trap to measure runtime from every command, then will run the specified code.
# the source code is generated and then sourced (instead of directly defined) so that things like the tmpdir/logfile path are hardcoded.
# this allows timep to run without adding any new (and potentially conflicting) variables to the code being run / time profiled.

# first 2 DEBUG trap commands must be to record number of PIPESTATUS elements and endtime
timep_DEBUG_TRAP_STR[0]='timep_NPIPE[${timep_NESTING_LVL}]="${#PIPESTATUS[@]}"
timep_ENDTIME="${EPOCHREALTIME}"
'
# main timep DEBUG trap
#
# we have already recorded the number of PIPESTATUS elements and the previous command end time
#
# first, check if BASHPID changed. if so, increase nesting/subshell lvl and re-set EXIT traps.
# else check for subshell exit (see if prev EXEC_N logfile exists). if so increment EXEC_N an extra time
# else check if last command was a bg fork. if so log thre pid/nexec
#
# second, check if we are entering/exiting a function
#
# third, check if this is a RETURN/EXIT trap firing
#
# lastly, resolve the current line number, write log line, update PREV variables, and record the start time for the command that is about to run

timep_DEBUG_TRAP_STR[1]='
if [[ -s "${timep_LOGPATH}.vars" ]]; then
    . "${timep_LOGPATH}.vars"
    : >"${timep_LOGPATH}.vars"
    (( timep_NESTING_LVL > timep_NESTING_LVL_0 )) && exec {timep_LOG_FD[${timep_NESTING_LVL}]}>"${timep_LOGPATH}"
    builtin trap '"'"'timep_EXIT_FLAG=true; :'"'"' EXIT
fi
if (( ${#FUNCNAME[@]} > timep_FUNCDEPTH_PREV )); then
    timep_NEXEC+=("0")
    timep_FUNCNAME_A+=("${FUNCNAME[0]}")
    timep_NO_PREV_FLAG=true
    (( timep_NESTING_LVL++ ))
    exec {timep_LOG_FD[${timep_NESTING_LVL}]}>"${timep_LOGPATH}"
    timep_NEXEC_STR+=".0"
    timep_FUNCNAME_STR+=".${FUNCNAME[0]}"
fi
if ${timep_NO_PREV_FLAG}; then
    timep_NO_PREV_FLAG=false
else
    {
        printf '"'"'%s\t'"'"' "${timep_NPIPE[${timep_NESTING_LVL}]}" "${timep_STARTTIME[${timep_NESTING_LVL}]}" "${timep_ENDTIME}" "${timep_LINENO[0]}.${timep_LINENO[1]}" "${timep_NEXEC_STR}" "${timep_BASHPID_STR}" "${timep_FUNCNAME_STR}"
        printf '"'"'%s\n'"'"' "${timep_BASH_COMMAND[${timep_NESTING_LVL}]}"
    } >&${timep_LOG_FD[${timep_NESTING_LVL}]}
fi
if ${timep_RETURN_FLAG}; then
    timep_LOGPATH="${timep_LOGPATH%.*}"
    timep_NEXEC_STR="${timep_NEXEC_STR%.*}"
    timep_FUNCNAME_STR="${timep_FUNCNAME_STR%.*}"
    exec {timep_LOG_FD[-1]}>&-
    (( timep_NESTING_LVL-- ))
    (( timep_FUNCDEPTH_PREV-- ))
    unset "timep_FUNCNAME_A[-1]" "timep_NEXEC[-1]" "timep_BASH_COMMAND[-1]" "timep_NPIPE[-1]" "timep_STARTTIME[-1]" "timep_LINENO[-1]" "timep_LOG_FD[-1]"
    timep_RETURN_FLAG=false
    timep_NO_PREV_FLAG=true
    timep_NO_NEXT_FLAG=true
    timep_BASH_COMMAND[${timep_NESTING_LVL}]="\<\< function: ${timep_BASH_COMMAND[${timep_NESTING_LVL}]} \>\>"
fi
if ${timep_EXIT_FLAG}; then
    timep_LOGPATH="${timep_LOGPATH%.*}"
    timep_NEXEC_STR="${timep_NEXEC_STR%.*}"
    timep_BASHPID_STR="${timep_BASHPID_STR%.*}"
    exec {timep_LOG_FD[-1]}>&-
    (( timep_NESTING_LVL-- ))
    (( timep_BASH_SUBSHELL_PREV-- ))
    unset "timep_BASHPID_A[-1]" "timep_NEXEC[-1]" "timep_BASH_COMMAND[-1]" "timep_NPIPE[-1]" "timep_STARTTIME[-1]" "timep_LINENO[-1]" "timep_LOG_FD[-1]"
    timep_EXIT_FLAG=false
    timep_NO_PREV_FLAG=true
    timep_NO_NEXT_FLAG=true
    timep_BASH_COMMAND[${timep_NESTING_LVL}]="\<\< subshell \>\>"
    declare -p timep_BASHPID_A timep_FUNCNAME_A timep_NEXEC timep_BASH_COMMAND timep_NPIPE timep_STARTTIME timep_LINENO timep_NEXEC_STR timep_BASHPID_STR timep_FUNCNAME_STR timep_LOG_FD timep_NESTING_LVL timep_NESTING_LVL_0 timep_BASH_SUBSHELL_PREV timep_LOGPATH timep_LOGPATH_0 >"${timep_LOGPATH_0}.vars"
fi
if ${timep_NO_NEXT_FLAG}; then
    timep_LINENO_0="${LINENO}"
    timep_LINENO_1="${timep_LINENO[${timep_NESTING_LVL}]#*.}"
    if [[ "${timep_LINENO[${timep_NESTING_LVL}]%.*}" == "${LINENO}" ]]; then
        (( timep_LINENO_1++ ))
    else
        timep_LINENO_1=0
    fi
    timep_LINENO[${timep_NESTING_LVL}]="${timep_LINENO_0}.${timep_LINENO_1}"
    timep_BASHPID_PREV="${BASHPID}"
    timep_FUNCNAME_PREV="${FUNCNAME[0]}"
    timep_FUNCDEPTH_PREV="${#FUNCNAME[@]}"
    timep_BASH_SUBSHELL_PREV="${BASH_SUBSHELL}"
    timep_BASH_COMMAND[${timep_NESTING_LVL}]="${BASH_COMMAND@Q}"
    (( timep_NEXEC[-1]++ ))
    timep_IFS_PREV="${IFS}"
    IFS='"'"'.'"'"'
    timep_NEXEC_STR="${timep_NEXEC[*]}"
    timep_BASHPID_STR="${timep_BASHPID_A[*]}"
    timep_FUNCNAME_STR="${timep_FUNCNAME_A[*]}"
    IFS="${timep_IFS_PREV}"
    unset timep_IFS_PREV
fi
if [[ "${timep_BASHPID_PREV}" != "${BASHPID}" ]] || (( timep_BASH_SUBSHELL_PREV < BASH_SUBSHELL )); then
    timep_LOGPATH_0="${timep_LOGPATH}"
    timep_NESTING_LVL_0="${timep_NESTING_LVL}"
    (( timep_BASH_SUBSHELL_DIFF = BASH_SUBSHELL - timep_BASH_SUBSHELL_PREV ))
    timep_KK=0
    timep_BASHPID_ADD=()
    while (( timep_BASH_SUBSHELL_DIFF > 0 )); do
        (( timep_BASH_SUBSHELL_DIFF-- ))
        case "${timep_KK}" in
            0) timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}]="${BASHPID}" ;;
            1) timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}]="${PPID}" ;;
            *) (( timep_BASH_SUBSHELL_DIFF0 = timep_BASH_SUBSHELL_DIFF + 1 )); IFS=" " read -r _ _ _ timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}] _ </proc/${timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF0}]} ;;
        esac
        (( timep_KK++ ))
        unset timep_BASH_SUBSHELL_DIFF0
    done
    unset timep_BASH_SUBSHELL_DIFF
    for timep_KK in "${timep_BASHPID_ADD[@]}"; do
        (( timep_NESTING_LVL++ ))
        (( timep_BASH_SUBSHELL_PREV++ ))
        timep_NEXEC+=("0")
        timep_BASHPID_A+=("${timep_KK}")
        timep_LINENO+=("${timep_LINENO[-1]}")
        timep_BASH_COMMAND+=("\<\< subshell \>\>")
        timep_NPIPE+=(1)
        timep_LOGPATH+=".0"
        timep_NEXEC_STR+=".0"
        timep_BASHPID_STR+=".${timep_KK}"
    done
    builtin trap '"'"'timep_EXIT_FLAG=true; :'"'"' EXIT
fi
if ${timep_NO_NEXT_FLAG}; then
    timep_NO_NEXT_FLAG=false
else
    if [[ "${timep_BG_PID_PREV}" != "${!}" ]]; then
        timep_BG_PID_PREV="${!}"
        printf '"'"'%s\t%s.%s\n'"'"' "${timep_NEXEC_STR}" "${timep_BASHPID_STR}" "${!}" >>"${timep_TMPDIR}/.log/bg_pids"
    fi
    timep_STARTTIME[${timep_NESTING_LVL}]=${EPOCHREALTIME}
fi
'
#elif (( ${#FUNCNAME[@]} < timep_FUNCDEPTH_PREV )) || [[ "${timep_FUNCNAME_PREV}" != "${FUNCNAME[0]}" ]]; then
#    timep_NO_PREV_FLAG=true

# overload the trap builtin to allow the use of custom EXIT/RETURN/DEBUG traps
trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap "${trapStr}"'timep_EXIT_FLAG=true; :' EXIT ;;
            RETURN)  builtin trap "${trapStr}"'timep_RETURN_FLAG=true; :' RETURN ;;
            DEBUG)   builtin trap "${timep_DEBUG_TRAP_STR[0]}${trapStr}${timep_DEBUG_TRAP_STR[1]}" DEBUG ;;
            *)       builtin trap "${trapStr}" "${trapType}" ;;
        esac
    done
}

    export -f trap

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
        f)
            _timep_getFuncSrc "$1" >"${timep_TMPDIR}/functions.bash"
            chmod +x "${timep_TMPDIR}/functions.bash"
            timep_runCmd1='#!'"$(type -p bash)"

            printf -v timep_runCmd '%q ' "${@}"
            [[ -t 0 ]] || timep_runCmd+=" <&0"

            # start of wrapper code
            timep_runFuncSrc="${timep_runCmd1}"$'\n''timep_runFunc() '
        ;;
    esac
timep_runFuncSrc+="(
printf '\\n
----------------------------------------------------------------------------
----------------------- RUNTIME BREAKDOWN BY COMMAND -----------------------
----------------------------------------------------------------------------

COMMAND PROFILED:
%s

START TIME:
%s (%s)

FORMAT (TAB-SEPERATED):
----------------------------------------------------------------------------
NPIPE  STARTTIME  ENDTIME  LINENO  NEXEC  BASHPID  FUNCNAME  BASH_COMMAND
----------------------------------------------------------------------------\\n\\n' \"$([[ "${timep_runType}" == 'f' ]] && printf '%s' "${timep_runCmd}" || printf '%s' "${timep_runCmdPath}")\" \"\$(date)\" \"\${EPOCHREALTIME}\" >\"\${timep_TMPDIR}\"/.log/format;

    declare timep_FUNCDEPTH_PREV timep_BASHPID_PREV timep_FUNCNAME_PREV timep_BG_PID_PREV timep_IFS_PREV timep_LOGPATH timep_LOGPATH_0 timep_ENDTIME timep_NESTING_LVL timep_NESTING_LVL_0 timep_NEXEC_STR timep_BASHPID_STR timep_FUNCNAME_STR timep_NO_PREV_FLAG timep_NO_NEXT_FLAG timep_EXIT_FLAG timep_RETURN_FLAG timep_TMPDIR timep_LINENO_0 timep_LINENO_1;
    declare -a timep_STARTTIME timep_BASH_COMMAND timep_LINENO timep_BASHPID_A timep_FUNCNAME_A timep_NEXEC timep_NPIPE timep_LOG_FD;

    set -T

    : & 2>/dev/null

    timep_BASHPID_A=(\"\${BASHPID}\")
    timep_FUNCNAME_A=('main')
    timep_NEXEC=(0)
    timep_BASHPID_PREV=\"\${BASHPID}\"
    timep_FUNCNAME_PREV='main'
    timep_FUNCDEPTH_PREV=\"\${#FUNCNAME[@]}\"
    timep_BG_PID_PREV=\"\${!}\"
    timep_BASH_SUBSHELL_PREV=\"\${BASH_SUBSHELL}\"
    timep_LINENO_0_PREV=0

    timep_NEXEC_STR=\"\${timep_NEXEC[*]}\"
    timep_BASHPID_STR=\"\${timep_BASHPID_A[*]}\"
    timep_FUNCNAME_STR=\"\${timep_FUNCNAME_A[*]}\"

    timep_EXIT_FLAG=false
    timep_RETURN_FLAG=false
    timep_NO_PREV_FLAG=true
    timep_NO_NEXT_FLAG=false

    timep_NESTING_LVL=0
    timep_NESTING_LVL_0=0
    timep_LINENO_0=${LINENO}
    timep_LINENO_1=0
    timep_LINENO[0]="${timep_LINENO_0}.${timep_LINENO_1}"
    timep_TMPDIR=\"${timep_TMPDIR}\"
    timep_LOGPATH=\"\${timep_TMPDIR}/.log/log\"
    timep_LOGPATH_0=\"\${timep_LOGPATH}\"
    timep_LOG_FD=()
    exec {timep_LOG_FD[0]}>\"\${timep_LOGPATH}\"
    mkdir -p \"\${timep_LOGPATH%/log}\"

    builtin trap 'timep_EXIT_FLAG=true; :' EXIT
    builtin trap 'timep_RETURN_FLAG=true; :' RETURN

    echo \"\$(( LINENO + 4 ))\" >\"\${timep_TMPDIR}/.log/lineno_offset\"

    builtin trap '${timep_DEBUG_TRAP_STR[@]//"'"/"'"'"'"'"'"'"'"}' DEBUG

    ${timep_runCmd}

    builtin trap - DEBUG EXIT RETURN;

)"

   # save script/function (with added debug trap) in new script file and make it executable
    echo "${timep_runFuncSrc}" >"${timep_TMPDIR}/main.bash"
    chmod +x "${timep_TMPDIR}/main.bash"

    case "${timep_runType}" in
    f)
        # source the original functions and then the wrapper function we just generated
        . "${timep_TMPDIR}/functions.bash"
        . "${timep_TMPDIR}/main.bash"

        # now actually run it
        if [[ -t 0 ]]; then
            timep_runFunc
        else
            timep_runFunc <&0
        fi
    ;;
    s)
        # run the script (with added debug trap)
        if [[ -t 0 ]]; then
           "${timep_TMPDIR}/main.bash" "${@}"
        else
           "${timep_TMPDIR}/main.bash" "${@}" <&0
        fi
    ;;
esac

printf '\n\nThe %s being time profiled has finished running!\ntimep will now process the logged timing data.\ntimep will save the time profiles it generates in "%s"\n\n' "$([[ "${timep_runType}" == 's' ]] && echo 'script' || echo 'function')" "${timep_TMPDIR}" >&2
unset IFS

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
        printf -v outCur0 '%s:  %s.%s sec \t <<--- (%sx) %s\n' "${linesCmdCur[0]%%:*}" "${tSum:0:$t6}" "${tSum:$t6}" "${#timesCmdCur[@]}" "${linesCmdCur[0]#*\<\<\-\-\- }"
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
)
