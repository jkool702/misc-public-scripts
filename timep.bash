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
    #        time.ALL:                    the individual per-command run times for every command reun under any pid. This is generated directly by the DEBUF trap as the code runs
    #        time.<pid>_<name>__<#>.<#>:  the individual per-command run times for a specific pid at shell/subshell nesting level <#>.<#>
    #        time.combined.<pid>_<#>.<#>: the combined time and run count for each unique command run by that pid. The <#>.<#> is $SHLVL.$BASH_SUBSHELL
    #        time.combined.ALL:           the time.combined.<pid>.<#>.<#> files from all pids combined into a single file.  This is printed to stderr at the end
    #
    # OUTPUT FORMAT: 
    #    for time.ALL profiles:                    [ $PID {$NAME_$SHLVL.$BASH_SUSBHELL} ]  $LINENO:  <run_time> sec  ( <start_time --> <end_time> ) <<--- { $BASH_CMD }
    #    for time.<pid>_<name>_<#>.<#> profiles:   $LINENO:  <run_time> sec  ( <start_time --> <end_time> )  <<--- { $BASH_CMD }
    #    for time.combined profiles:               $LINENO:  <total_run_time> sec  <<--- (<run_count>x) { $BASH_CMD }
    #        NOTE: all profiles except time.ALL will list $PID and $NAME and $SHLVL.$BASH_SUBSHELL at the top of the file
    #        "combined" example: if CMD runs 5 times in a loop, you will get a line with "<total_run_time> sec  <<--- (5x) { CMD }".
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
    #    Additionally, timep adds a few variables + functions to the runtime env of whatever is being profiled. The code being profiled must NOT modify these.
    #        FUNCTIONS:  _timep_getTimeDiff  _timep_printTimeDiff
    #        VARIABLES:  timep_STARTTIME  timep_ENDTIME  timep_BASH_COMMAND_PREV  timep_LINENO_PREV timep_BASHPID_PREV  timep_TMPDIR
    #
    # DEPENDENCIES:
    #    1) a recent-ish bash version (4.0+ (???) - it needs to support the $EPOCHREALTIME variable)
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
    #        $timep_TMPDIR that defines our DEGUB trap followed by the contents of the original script. 
    #        this new script is called with any arguments passed on the timep commandline (if no flags: ${2}+).
    #    if the command being profiled is a shell function (or, in general, NOT a shell script), timep will create a new
    #        shell function (runFunc) that defines our DEGUB trap and then calls whatever commandline was passed to timep.
    #        this then gets re-sourced (via `. <(declare -f runFunc)`) to make $LINENO give meaningful line numbers.
    #    the intent is to run scripts as scripts and functions as functions, so that things like $0 and $BASH_SOURCE work as expected.
    #    for both scripts and functions, if stdin is not a terminal then it is passed to the stdin of the code being profiled.
    #
    ################################################################################################################################################################

    shopt -s extglob

    local timep_runType=''

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
    
# define helper functions
_timep_getTimeDiff () {
## returns the time difference between 2 $EPOCHREALTIME times
    local d d6;
    printf -v d '%.07d' $(( ${2//./} - ${1//./} ));
    d6=$(( ${#d} - 6 ));
    printf '%s.%s\n' "${d:0:$d6}" "${d:$d6}"
};

_timep_printTimeDiff() {
## prints a line in the format of the time.ALL log file
# 7 inputs: $BASHPID $NAME $SHLVL.$BASH_SUBSHELL $LINENO tStart tEnd $BASH_COMMAND
    local tStart tEnd shellName
    
    [[ "${5}" ]] && tStart="${5}" || { [[ -f "${timep_TMPDIR}/.run.time.start.last" ]] && read -r tStart <"${timep_TMPDIR}/.run.time.start.last"; }
    
    [[ "${6}" ]] && tEnd="${6}" || tEnd="${EPOCHREALTIME}"

    shellName="${2##*/}"

    [[ $tStart ]] || {
    printf '[ %s {%s_%s} ]  %s:  ERROR ( ??? --> %s ) <<--- { %s }\n' "$1" "${shellName// /.}" "$3" "$4" "$tEnd" "${7//$'\n'/'$'"'"'\n'"'"}" 
        return 1
    }
    
    printf '[ %s {%s_%s} ]  %s:  %s sec  ( %s --> %s ) <<--- { %s }\n' "$1" "${shellName// /.}" "$3" "$4" "$(_timep_getTimeDiff "$tStart" "$tEnd")" "$tStart" "$tEnd" "${7//$'\n'/'$'"'"'\n'"'"}" 
}

    export -f _timep_getTimeDiff
    export -f _timep_printTimeDiff    
    export timep_TMPDIR="${timep_TMPDIR}"

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
        ;;
        f)
            if [[ -t 0 ]]; then
                timep_runCmd="${@}"
            else
                timep_runCmd="cat | ${@}"
            fi
        ;;
    esac

# generate the code for a wrapper function (timep_runFunc) that wraps around whatever we are running / time profiling.
# this will setup a DEBUG trap to measure runtime from every command, then will run the specified code.
# the source code is generated and then sourced (instead of directly defined) so that things like the tmpdir/logfile path are hardcoded.
# this allows timep to run without adding any new (and potengtially conflicting) variables to the code being run / time profiled.
case "${timep_runType}" in
    f)  timep_runFuncSrc='timep_runFunc () '  ;;
    s)  timep_runFuncSrc="${timep_runCmd1}"$'\n'  ;;
esac
timep_runFuncSrc+="(
printf '\n
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
----------------------------------------------------------------------------\n\n' \"$([[ "${timep_runType}" == 'f' ]] && printf '%s' "${timep_runCmd}" || printf '%s' "${timep_runCmdPath}")\" \"\$(date)\" \"\$EPOCHREALTIME\" >&\${fd_timep};
    echo \"\$EPOCHREALTIME\" > \"$timep_TMPDIR\"/.run.time.start.last;
    local timep_STARTTIME timep_ENDTIME timep_BASH_COMMAND_PREV timep_LINENO_PREV timep_BASHPID_PREV
    timep_BASHPID_PREV=\"\$BASHPID\"
    set -T;
    trap ':' RETURN;
    trap '[[ \"\$timep_BASHPID_PREV\" == \"\$BASH_PID\" ]] || { declare +g -I timep_STARTTIME timep_ENDTIME timep_BASH_COMMAND_PREV timep_LINENO_PREV timep_BASHPID_PREV; timep_BASHPID_PREV="\$BASHPID"; };
timep_ENDTIME=\"\$EPOCHREALTIME\";
_timep_printTimeDiff \"\$BASHPID\"  \"\${FUNCNAME:-\"\${BASH_SOURCE:-\"\${0}\"}\"}\" \"\${SHLVL}.\${BASH_SUBSHELL}\" \"\$timep_LINENO_PREV\" \"\$timep_STARTTIME\" \"\$timep_ENDTIME\" \"\$timep_BASH_COMMAND_PREV\" >&\${fd_timep};
timep_BASH_COMMAND_PREV=\"\$BASH_COMMAND\";
timep_LINENO_PREV=\"\$LINENO\"
timep_STARTTIME=\"\$EPOCHREALTIME\";
echo \"\$timep_STARTTIME\" >\"${timep_TMPDIR}\"/.run.time.start.last;' DEBUG;

${timep_runCmd}

trap - DEBUG

) {fd_timep}>\"${timep_TMPDIR}\"/time.ALL"

case "${timep_runType}" in
    f)  
        # source the wrapper function we just generated
        eval "${timep_runFuncSrc}"

        # source it again by using declare -f in a command substitution
        # this may seem silly because it IS silly...but, it makes $LINENO give meaningful line numbers in the DEBUG trap
        . <(declare -f timep_runFunc)

        # now actually run it
        timep_runFunc
    ;;
    s)  
        # save script (with added debug trap) in new script file and make it executable
        echo "${timep_runFuncSrc}" >"${timep_TMPDIR}"/main.bash
        chmod +x "${timep_TMPDIR}"/main.bash

        # run the script (with added debug trap)
        "${timep_TMPDIR}"/main.bash "${@}"
    ;;
esac



printf '\n\nThe code being time profiled has finished running!\ntimep will now process the logged timing data.\n\n' >&2

# get lists of unique commands run (unique combinations of pid + subshell level in the logged data
mapfile -t uniq_pids < <(grep -E '^\[ [0-9]+ \{[^ ]*_[0-9\.]+\} \]' "${timep_TMPDIR}/time.ALL" 2>/dev/null | sed -E s/'^\[ ([0-9]+) \{([^ ]*_[0-9]+\.[0-9]+)\} \] .*$'/'\1_\2'/ | sort -u)

tSumAllAll0=0
for p in "${uniq_pids[@]}"; do
    # print header with PID and shell nesting level >"${timep_TMPDIR}/time.${p}"
    # seperate out the data for each pid and save it in a file called time.<pid>
    p0="${p%%_*}"
    p1="${p#*_}"
    grep -E '^\[ '"${p0}"' \{'"${p1}"'\} \]' "${timep_TMPDIR}/time.ALL" 2>/dev/null | sed -E s/'^\[ [0-9]+ \{[0-9\.]+\} \] +'// >>"${timep_TMPDIR}/time.${p}"

    # find the unique commands (pid + subshell_lvl + line number + cmd) from just this pid/subshell_lvl
    mapfile -t uniq_lines_pid < <(grep -v -E '^((PID)|(NAME)|(NESTING)|([0-9]+\:[[:space:]]+ERROR)|\:|$)' 2>/dev/null <"${timep_TMPDIR}/time.$p" | sed -E 's/:[^<:]+<<\-\-\- /: /' | sort -u)
    outCur=()
    kk=0

    printf 'PID:        \t%s\nNAME:        \t%s\nNESTING LVL:\t%s\n' "${p0}" "${p1%_*}" "${p1##*_}"
    tSumAll0=0
    # for each unique command run by this unique command, pull out the run count and pull out the run times and sum them together
    # print a line to the time.combined.<pid> file vcontaining the run count and the combined run time for that command
    # also, keep track of total run time for this PID
    for l in "${uniq_lines_pid[@]}"; do
        [[ $l ]] || continue
        mapfile -t linesCmdCur < <(grep -F "${l#*:}" "${timep_TMPDIR}/time.$p" 2>/dev/null | grep -E '^'"${l%%:*}" 2>/dev/null)
        timesCmdCur=("${linesCmdCur[@]#*:  }")
        timesCmdCur=("${timesCmdCur[@]%% sec*}")
        timesCmdCur=("${timesCmdCur[@]//./}")
        timesCmdCur=("${timesCmdCur[@]//-+(0)/-}")
        tSum0="$(( $(printf '%s + ' "${timesCmdCur[@]##+(0)}") 0 ))"
        (( tSumAll0+=tSum0 ))
        printf -v tSum '%.07d' "$tSum0"
        t6=$(( ${#tSum} - 6 ))
        printf -v outCur0 '%s:  %s.%s sec \t <<--- (%sx) %s\n' "${linesCmdCur[0]%%:*}" "${tSum:0:$t6}" "${tSum:$t6}" "${#timesCmdCur[@]}" "${linesCmdCur[0]#*\<\<\-\-\- }"
        outCur+=("${outCur0}")
    done 
    (( tSumAllAll0+=tSumAll0 ))
    printf -v tSumAll '%.07d' "$tSumAll0"
    t6=$(( ${#tSumAll} - 6 ))
    printf -v outCur0 '\n\nTOTAL TIME FOR PID %s {%s}: %s.%s sec\n\n\n' "${p0}" "${p1}" "${tSumAll:0:$t6}" "${tSumAll:$t6}"
    outCur+=("${outCur0}")
    printf '%s\n' "${outCur[@]}" | sort -g -k1 >"${timep_TMPDIR}/time.combined.$p"
done

printf -v tSumAllAll '%.07d' "$tSumAllAll0"
t6=$(( ${#tSumAllAll} - 6 ))


printf '
The following time profile is seperated by process ID (pid). 
For each line/command run in each pid, the total combined time from all evaluations (as well as the number of evaluations) is shown

FORMAT:
----------------------------------------------------------------------------
LINENO:  TOTAL_RUNTIME <<--- (COUNTx) { CMD }
----------------------------------------------------------------------------

TOTAL COMBINED RUN TIME: %s.%s SECONDS

' "${tSumAllAll:0:$t6}" "${tSumAllAll:$t6}" >"${timep_TMPDIR}"/time.combined.ALL
cat "${timep_TMPDIR}"/time.combined.[0-9]* | sed -z -E s/'\n{3,}'/'\n\n\n'/g >> "${timep_TMPDIR}"/time.combined.ALL
printf '\n\nAdditional time profiles, including non-combined ones that show individual command runtimes, can be found under:\n    %s\n\n' "${timep_TMPDIR}" >>"${timep_TMPDIR}"/time.combined.ALL
cat "${timep_TMPDIR}"/time.combined.ALL >&2

export -n timep_TMPDIR
export -nf _timep_getTimeDiff
export -nf _timep_printTimeDiff  
#\rm -f "${timep_TMPDIR}"/.timep.*
#if ! [[  "${timep_TMPDIR}" == "$PWD" ]] && { { shopt nullglob &>/dev/null && [[ -z $(printf '%s' "${timep_TMPDIR}"/*) ]]; } || { ! shopt nullglob &>/dev/null && [[ "$(printf '%s' "${timep_TMPDIR}"/*)" == "${timep_TMPDIR}"'/*' ]]; }; }; then 
#    \rm -r "${timep_TMPDIR}"
#fi
    
)
