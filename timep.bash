#!/usr/bin/env bash

shopt -s extglob

timep() (
    ## TIME Profile - efficiently produces an accurate per-command execution time profile for shell scripts and functions using a DEBUG trap
    #
    # USAGE:     timep [-s|-f] [--] _______          --OR--
    #    [...] | timep [-s|-f] [--] _______ | [...]
    #
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
    #    Flags must be given before the command being profiled. if multiple -s/-f are given the last one is used/.
    #    -s | --shell    : force timep to treat the code being profiled as a shell script
    #    -f | --function : force timep to treat the code being profiled as a shell function
    #    --              : stop arg parsing (allows propfiling something with the same name as a flag)
    #    DEFAULT: Attempt to automatically detect shell scripts (*requires `file` for robust detection). 
    #             Assume a shell function unless detection explicitly indicates a shell script.
    #
    # RUNTIME CONDITIONS/REQUIREMENTS:
    #    It is REQUIRED that the shell script/function you are generating the time profile for does NOT use a DEBUG trap ANYWHERE.
    #        timep works by "hijacking" the DEBUG trap, and if the code alters the DEBUG traop then timep will stop working.
    #    Additionally, timep adds a several variables (all which start with "timep_") + function(s) to the runtime env of whatever is being profiled. The code being profiled must NOT modify these.
    #        FUNCTIONS:  _timep_printTimeDiff
    #        VARIABLES:  timep_ID timep_ID_PREV timep_FUNCDEPTH_PREV timep_BASH_SUBSHELL_PREV timep_BASHPID_PREV timep_BG_PID_PREV timep_TRAP_TYPE timep_ENDTIME timep_RUNTIME_CUR timep_LINE_OUT timep_PPID timep_STARTTIME timep_ENDTIME timep_BASH_COMMAND timep_LINENO timep_NESTING timep_BASHPID timep_FUNCNAME timep_RUNTIME_SUM;
    #
    # DEPENDENCIES:
    #    1) bash 5.0+ (it needs to support the $EPOCHREALTIME variable)
    #    2) sed, grep, sort, mkdir, file*
    #
    # NOTES: 
    #    1. Scripts using RETURN traps MAY not work as expected. "set -T" is used to propogate the DEBUG trap into shell functions,
    #         which also propogates RETURN traps into shell functions. This may or may not cause unexpected "RETURN trap"-related behavior.
    #    2. The line numbers may not correspond exactly to the line numbers in the original code, but will ensure commamds are ordered correctly.
    #    3. Any shell scripts called by the top-level script/function being profiled will NOT have their runtimes profiled, since the DEBUG trap doesnt propogate to sripts.
    #         To profile these, either source them (instead of calling them) or call them via `timep -s <script>`. However, shell functions that are called WILL automatically be profiled.
    #    4. To define a custom TMPDIR, pass `timep_TMPDIR` as an environment variable. e.g., timep_TMPDIR=/path/to/tmpdir timep codeToProfile
    #
    # DIFFERENCES IN HOW SCRIPTS AND FUNCTIONS ARE HANDLED
    #    if the command being profiled is a shell script, timep will create a new script file under
    #        $timep_TMPDIR that defines our DEBUG trap followed by the contents of the original script. 
    #        this new script is called with any arguments passed on the timep commandline (if no flags: ${2}+).
    #    if the command being profiled is a shell function (or, in general, NOT a shell script), timep will create a new
    #        shell function (runFunc) that defines our DEBUG trap and then calls whatever commandline was passed to timep.
    #        this then gets re-sourced (via `. <(declare -f runFunc)`) to make $LINENO give meaningful line numbers.
    #    the intent is to run scripts as scripts and functions as functions, so that things like $0 and $BASH_SOURCE work as expected.
    #    for both scripts and functions, if stdin is not a terminal then it is passed to the stdin of the code being profiled.
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
        mkdir -p "$timep_TMPDIR" || timep_TMPDIR=''
    }

    # try /tmp
    [[ "$timep_TMPDIR" ]] || {
        timep_TMPDIR=/tmp/.timep."$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$timep_TMPDIR" ]]; do
            timep_TMPDIR=/tmp/.timep."$(printf '%X' ${RANDOM}${RANDOM:1})"
        done        
        mkdir -p "$timep_TMPDIR" || timep_TMPDIR=''
    }

    # try $PWD
    [[ "$timep_TMPDIR" ]] || {
        timep_TMPDIR="$PWD/.timep.$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$timep_TMPDIR" ]]; do
            timep_TMPDIR="$PWD/.timep.$(printf '%X' ${RANDOM}${RANDOM:1})"
        done   
        mkdir -p "$timep_TMPDIR" || timep_TMPDIR=''
    }

    # ABORT if we couldnt get a writable TMPDIR
     [[ "$timep_TMPDIR" ]] || {
         printf '\nERROR: could not create a tmpdir under /dev/shm nor /tmp nor PWD (%s). \nPlease ensure you have requisite write permissions in one of these directories. ABORTING\n\n' "$PWD"
         return 1
    }

    # determine if command being profiled is a shell script or not
    [[ ${timep_runType} == [sf] ]] || {
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
            elif [[ "${timep_runCmdPath}" == *.*sh ]] && read -r <"${1}" && [[ "${REPLY}" == '#!'* ]]; then
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
    }    

    export timep_runType="${timep_runType}"


_timep_printTimeDiff() {
## prints a line in the format of the time.ALL log file
# 7 inputs: $BASHPID $NAME $SHLVL.$BASH_SUBSHELL $LINENO tStart tEnd $BASH_COMMAND
    local tStart tEnd tDiff d d6 shellName timep_LINENO_OFFSET
    
    [[ "${5}" ]] && tStart="${5}" #|| { [[ -f "${timep_TMPDIR}/.run.time.start.last" ]] && read -r tStart <"${timep_TMPDIR}/.run.time.start.last"; }
    
    [[ "${6}" ]] && tEnd="${6}" || tEnd="${EPOCHREALTIME}"

    shellName="${2##*/}"

    if [[ $tStart ]]; then
        printf -v d '%.07d' "${8}"
        d6=$(( ${#d} - 6 ))
        printf -v tDiff '%s.%s' "${d:0:$d6}" "${d:$d6}"
    fi

    if [[ -z ${FUNCNAME} ]]; then
        if [[ -f "${timep_TMPDIR}/.lineno.offset" ]]; then
            read -r timep_LINENO_OFFSET <"${timep_TMPDIR}/.lineno.offset"
        else
            [[ ${4} ]] && echo "${4}" >"${timep_TMPDIR}/.lineno.offset"
            timep_LINENO_OFFSET="$4"
        fi

        if [[ $tStart ]]; then
            printf -v timep_LINE_OUT '[ %s.%s {%s} ]  %s:  %s sec  ( %s --> %s ) <<--- { %s }\n' "$1" "${shellName// /.}" "$3" "$(( ${4} - timep_LINENO_OFFSET + 1 ))" "${tDiff}" "$tStart" "$tEnd" "${7//$'\n'/'$'"'"'\n'"'"}" 
        else
            printf -v timep_LINE_OUT '[ %s.%s {%s} ]  %s:  ERROR ( ??? --> %s ) <<--- { %s }\n' "$1" "${shellName// /.}" "$3" "$(( ${4} - timep_LINENO_OFFSET + 1 ))" "$tEnd" "${7//$'\n'/'$'"'"'\n'"'"}" 
            return 1
        fi    
    else
        if [[ $tStart ]]; then
            printf -v timep_LINE_OUT '[ %s.%s {%s} ]  %s:  %s sec  ( %s --> %s ) <<--- { %s }\n' "$1" "${shellName// /.}" "$3" "$4" "${tDiff}" "$tStart" "$tEnd" "${7//$'\n'/'$'"'"'\n'"'"}" 
        else
            printf -v timep_LINE_OUT '[ %s.%s {%s} ]  %s:  ERROR ( ??? --> %s ) <<--- { %s }\n' "$1" "${shellName// /.}" "$3" "$4" "$tEnd" "${7//$'\n'/'$'"'"'\n'"'"}" 
            return 1
        fi    
    fi
}

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}; "
        shift 1
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap "${trapStr}"'timep_EXIT_FLAG=true' EXIT ;;
            RETURN)  builtin trap "${trapStr}"'timep_RETURN_FLAG=true' RETURN ;;
            DEBUG)   builtin trap "${timep_DEBUG_TRAP_STR[0]}""${trapStr}""${timep_DEBUG_TRAP_STR[1]}" DEBUG ;;
            *)       builtin trap "${trapStr}" "${trapType}" ;;
        esac
    done
}

    export -f trap
    export -f _timep_printTimeDiff    
    export timep_TMPDIR="${timep_TMPDIR}"

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

            declare -F "$1" &>/dev/null && . <(declare -f "$1")
            printf -v timep_runCmd '%q ' "${@}"
            [[ -t 0 ]] || timep_runCmd+=" <&0"
            
            # start of wrapper code
            timep_runFuncSrc='timep_runFunc () '
        ;;
    esac
    
# generate the code for a wrapper function (timep_runFunc) that wraps around whatever we are running / time profiling.
# this will setup a DEBUG trap to measure runtime from every command, then will run the specified code.
# the source code is generated and then sourced (instead of directly defined) so that things like the tmpdir/logfile path are hardcoded.
# this allows timep to run without adding any new (and potentially conflicting) variables to the code being run / time profiled.

# first 2 DEBUG trap commands must be to record number of PIPESTATUS elements and endtime
timep_DEBUG_TRAP_STR[0]='timep_NPIPE[${#timep_NEXEC[@]}]="${#PIPESTATUS[@]}"
timep_ENDTIME="${EPOCHREALTIME}"
'

# main timep DEBUG trap
#
# we have already recorded the number of PIPESTATUS elements and the previous command end time
#
# first, check if BASHPID changed. if so, increase nesting/subshell lvl. reset RETURN/EXIT traps, and check TPGID to determine if it was a subshell or a fork
#    if fork then start new log tree by setting the logpath root to the current PID
# else check for subshell exit (see if prev EXEC_N logfile exists). if so increment EXEC_N an extra time 
# else check if last command was a bg fork
#
# second, check if we are entering/exiting a function
#
# third, check if this is a RETURN/EXIT trap firing
#
# lastly, resolve the current line number, write log line, update PREV variables, and record the start time for the command that is about to run

timep_DEBUG_TRAP_STR[1]='
timep_IFS_PREV="${IFS}"; IFS='"''"'.'"''"';
timep_NEXEC_STR="${timep_NEXEC[*]}"
IFS='"''"'>'"''"'
timep_BASHPID_STR="${timep_BASHPID_A[*]}"
timep_FUNCNAME_STR="${timep_FUNCNAME_A[*]}"
IFS="${timep_IFS_PREV}"; unset timep_IFS_PREV;
if [[ "${timep_BASHPID_PREV}" == "${BASHPID}" ]]; then
    if [[ -f "${timep_LOGPATH}.${timep_NEXEC[-1]}" ]]; then
        timep_BASH_COMMAND[${#timep_NEXEC[@]}]="<< subshell >>"
    elif [[ "${timep_BG_PID_PREV}" != $! ]]; then
        timep_BG_PID_PREV=$!
        timep_BASH_COMMAND[${#timep_NEXEC[@]}]+=$'"'"'\n'"'"'"<< background fork: ${!} >>"
    fi
else
    read -r _ _ _ _ _ _ _ timep_TPGID _ </proc/${BASHPID}/stat
    timep_BASHPID_A+=("${BASHPID}")
    timep_BASHPID_STR+=">${BASHPID}"
    if [[ "${timep_TPGID}" == "${BASHPID}" ]]; then       
        timep_LOGPATH+=".${timep_NEXEC[-1]}"
    else
        timep_LOGPATH="${timep_TMPDIR}/.log/${timep_BASHPID_STR//\>/.}/log.${timep_NEXEC_STR}"
        mkdir -p "${timep_TMPDIR}/.log/${timep_BASHPID_STR//\>/.}"
    fi
    timep_NEXEC+=("0")
    timep_NEXEC_STR+=".${timep_NEXEC[-1]}"
    timep_BASHPID_STR+=">${BASHPID}"
    exec {timep_LOG_FD[${#timep_NEXEC[@]}]}>"${timep_LOGPATH}"
    timep_NO_PREV_FLAG=true
    trap '"''"' EXIT RETURN
    set -m
fi
if (( ${#FUNCNAME[@]} > timep_FUNCDEPTH_PREV )); then
    timep_NEXEC+=("0")
    timep_NEXEC_STR+=".${timep_NEXEC[-1]}"
    timep_FUNCNAME_STR+=">${FUNCNAME[0]}"
    timep_NO_PREV_FLAG=true
    timep_FUNCNAME_A+=("${FUNCNAME[0]}")
    timep_LOGPATH+=".${timep_NEXEC[-1]}"
    exec {timep_LOG_FD[${#timep_NEXEC[@]}]}>"${timep_LOGPATH}"
elif (( ${#FUNCNAME[@]} < timep_FUNCDEPTH_PREV )); then
    timep_LOGPATH="${timep_LOGPATH%.*}"
    timep_BASH_COMMAND[${#timep_NEXEC[@]}]="<< function: ${timep_FUNCNAME_A[${#timep_NEXEC[@]}]} >>"
    unset "timep_FUNCNAME_A[-1]" "timep_NEXEC[-1]" "timep_BASH_COMMAND[-1]" "timep_NPIPE[-1]" "timep_STARTTIME[-1]"
    timep_RETURN_FLAG=false
fi
if ${timep_EXIT_FLAG} && ${timep_RETURN_FLAG}; then
    timep_NO_PREV_FLAG=true
    timep_NO_NEXT_FLAG=true
elif ${timep_EXIT_FLAG} || ${timep_RETURN_FLAG}; then
    timep_NO_NEXT_FLAG=true
fi
timep_LINENO[0]=${LINENO}
if [[ "${timep_LINENO_PREV}" == "${LINENO}" ]]; then
    (( timep_LINENO[1] += 1 ))
else
    timep_LINENO[1]=0
fi
if ${timep_NO_PREV_FLAG}; then
    timep_NO_PREV_FLAG=false
else
    {
        printf '"''"'%s\t'"''"' "${timep_NPIPE[${#timep_NEXEC[@]}]}" "${timep_STARTTIME[${#timep_NEXEC[@]}]}" "${timep_ENDTIME}" "${timep_LINENO[0]}.${timep_LINENO[1]}" "${timep_NEXEC_STR}" "${timep_BASHPID_STR}" "${timep_FUNCNAME_STR}"
        printf '"''"'%s\n'"''"' "${timep_BASH_COMMAND[#timep_NEXEC[@]}]}"
    } >&${timep_LOG_FD[${#timep_NEXEC[@]}]}
fi
if ${timep_NO_NEXT_FLAG}; then
    exec {timep_LOG_FD[${#timep_NEXEC[@]}]}>&-
    unset "timep_LOG_FD[${#timep_NEXEC[@]}]"
else
    timep_BASHPID_PREV="${BASHPID}"
    timep_FUNCDEPTH_PREV="${#FUNCNAME[@]}"
    timep_LINENO_PREV="${LINENO}" 
    (( timep_NEXEC[-1] += 1 ))
    timep_STARTTIME[${#timep_NEXEC[@]}]=${EPOCHREALTIME}
fi
'

timep_runFuncSrc+="(
printf '\\n
----------------------------------------------------------------------------
----------------------- RUNTIME BREAKDOWN BY COMMAND -----------------------
----------------------------------------------------------------------------

COMMAND PROFILED:
%s

START TIME: 
%s (%s)

FORMAT:
----------------------------------------------------------------------------
[ PID {NAME.SHLVL.NESTING} ]  LINENO:  RUNTIME  (TSTART --> TSTOP) <<--- { CMD }
----------------------------------------------------------------------------\\n\\n' \"$([[ "${timep_runType}" == 'f' ]] && printf '%s' "${timep_runCmd}" || printf '%s' "${timep_runCmdPath}")\" \"\$(date)\" \"\${EPOCHREALTIME}\" >\"\${timep_TMPDIR}\"/time.ALL;
    declare timep_FUNCDEPTH_PREV timep_BASHPID_PREV timep_LINENO_PREV timep_BG_PID_PREV timep_IFS_PREV timep_LOGPATH timep_ENDTIME timep_NEXEC_STR timep_BASHPID_STR timep_FUNCNAME_STR timep_NO_PREV_FLAG timep_NO_NEXT_FLAG timep_EXIT_FLAG timep_RETURN_FLAG;
    declare -a timep_STARTTIME timep_BASH_COMMAND timep_LINENO timep_BASHPID_A timep_FUNCNAME_A timep_NEXEC timep_NPIPE timep_LOG_FD;

    set -T;
    set -m;

    timep_BASHPID_A=(\"\${BASHPID}\");
    timep_FUNCNAME_A=('main');
    timep_NEXEC=(0)
    timep_BASHPID_PREV=\"\${BASHPID}\";
    timep_FUNCDEPTH_PREV=\"\${#FUNCNAME[@]}\";
    timep_BG_PID_PREV=\"\$!\";

    timep_EXIT_FLAG=false
    timep_RETURN_FLAG=false
    timep_NO_PREV_FLAG=false
    timep_NO_NEXT_FLAG=false

    timep_LOGPATH=\"\${timep_TMPDIR}/.log/\${BASHPID}/log\"
    timep_LOG_FD=()
    exec {timep_LOG_FD[0]}>\"\${timep_LOGPATH}\"
    mkdir -p \"\${timep_LOGPATH%/log}\"
    trap '' DEBUG;

    ${timep_runCmd}

    builtin trap - DEBUG EXIT RETURN;

)"

case "${timep_runType}" in
    f)  
        # source the wrapper function we just generated
        eval "${timep_runFuncSrc}"

        # source it again by using declare -f in a command substitution
        # this may seem silly because it IS silly...but, it makes $LINENO give meaningful line numbers in the DEBUG trap
        . <(declare -f timep_runFunc)

        # now actually run it
        if [[ -t 0 ]]; then
            timep_runFunc
        else
            timep_runFunc <&0
        fi
    ;;
    s)  
        # save script (with added debug trap) in new script file and make it executable
        echo "${timep_runFuncSrc}" >"${timep_TMPDIR}"/main.bash
        chmod +x "${timep_TMPDIR}"/main.bash

        # run the script (with added debug trap)
        if [[ -t 0 ]]; then
            "${timep_TMPDIR}"/main.bash "${@}"
        else
            { "${timep_TMPDIR}"/main.bash "${@}"; } <&0
        fi        
    ;;
esac

printf '\n\nThe %s being time profiled has finished running!\ntimep will now process the logged timing data.\ntimep will save the time profiles it generates in "%s"\n\n' "$([[ "${timep_runType}" == 's' ]] && echo 'script' || echo 'function')" "${timep_TMPDIR}" >&2
unset IFS

# TO DO
##### AFTER the code has finished running, a post-processing phase will:
# 1. identify commands that are parts of pipelines by lookig for NPIPE > 1. NPIPE is greater that 1 for a single DEBUG trap firing after a pipeline has finished.
# 2. starting with the most deeply nested logs, compute the total run time (by summing the individual command runtimes), then merge the log upwad into the "placeholder line" in the parent's log. use the summer runtime (not end time - start time) for this "placeholder line" so that the runtime profile is minimally affected by the timing instrumentation

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
    
)
