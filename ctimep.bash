#!/usr/bin/env bash

shopt -s extglob

ctimep() (
    ## Command TIME Profile - efficiently produces an accurate per-command execution time profile for shell scripts and functions using a DEBUG trap
    #
    # USAGE:     ctimep _______          --OR--
    #    [...] | ctimep _______ | [...]
    #
    # OUTPUT: 
    #    4 types of time profiles will be saved to disk in ctimep's tmpdir directory (a new directory under /dev/shm or /tmp or $PWD - printed to stderr at the end):
    #        time.ALL:                  the individual per-command run times for every command reun under any pid. This is generated directly by the DEBUF trap as the code runs
    #        time.<pid>_<#.#>:          the individual per-command run times for a specific pid at shell/subshell nesting level <#.#>
    #        time.combined.<pid>_<#.#>: the combined time and run count for each unique command run by that pid. e.g., if a command runs 5 times in a loop, you will get a line that includes "... <<--- (5x) <total run time>"
    #        time.combined.ALL:         the time.combined.<pid>.<#.#> files from all pids combined into a single file.  This is printed to stderr at the end
    #
    # OUTPUT FORMAT: 
    #    for time.ALL profiles:           [ $PID {$SHLVL.$BASH_SUSBHELL} ]  $LINENO:  <run_time> sec  ( <start_time --> <end_time> ) <<--- { $BASH_CMD }
    #    for time.<pid>_<#.#> profiles:   $LINENO:  <run_time> sec  ( <start_time --> <end_time> )  <<--- { $BASH_CMD }
    #    for time.combined profiles:      $LINENO:  <total_run_time> sec  <<--- (<run_count>x) { $BASH_CMD }
    #        NOTE: all profiles except time.ALL will list $PID and $SHLVL.$BASH_SUBSHELL at the top of the file
    #
    # RUNTIME CONDITIONS/REQUIREMENTS:
    #    It is REQUIRED that the shell script/function you are generating the time profile for does NOT use a DEBUG trap ANYWHERE.
    #        ctimep works by "hijacking" the DEBUG trap, and if the code alters the DEBUG traop then ctimep will stop working.
    #    Additionally, ctimep adds a few variables + functions to the runtime env of whatever is being profiled. The code being profiled must NOT modify these.
    #        FUNCTIONS:  _ctimep_getTimeDiff  _ctimep_printTimeDiff
    #        VARIABLES:  ctimep_STARTTIME  ctimep_ENDTIME  ctimep_BASH_COMMAND_PREV  ctimep_LINENO_PREV ctimep_BASHPID_PREV  ctimep_TMPDIR
    #
    # NOTES: 
    #    Scripts using RETURN traps MAY not work as expected. "set -T" is used to propogate the DEBUG trap into shell functions,
    #        which also propogates RETURN traps into shell functions. This may or may not cause unexpected "RETURN trap"-related behavior.
    #
    # DEPENDENCIES:
    #    1) a recent-ish bash version (4.0+ (???) - it needs to support the $EPOCHREALTIME variable)
    #    2) sed, grep, sort, mkdir

    shopt -s extglob

    # figure out where to setupo a tmpdir to use (prefferably on a ramdisk/tmpfs)

    ctimep_TMPDIR=''

    # try /dev/shm
    [[ -d /dev/shm ]] && { 
        ctimep_TMPDIR=/dev/shm/.bash.cmd.time."$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$ctimep_TMPDIR" ]]; do
            ctimep_TMPDIR=/dev/shm/.bash.cmd.time."$(printf '%X' ${RANDOM}${RANDOM:1})"
        done
        mkdir -p "$ctimep_TMPDIR" || ctimep_TMPDIR=''
    }

    # try /tmp
    [[ "$ctimep_TMPDIR" ]] || {
        ctimep_TMPDIR=/tmp/.bash.cmd.time."$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$ctimep_TMPDIR" ]]; do
            ctimep_TMPDIR=/tmp/.bash.cmd.time."$(printf '%X' ${RANDOM}${RANDOM:1})"
        done        
        mkdir -p "$ctimep_TMPDIR" || ctimep_TMPDIR=''
    }

    # try  $PWD
    [[ "$ctimep_TMPDIR" ]] || {
        ctimep_TMPDIR="$PWD/.bash.cmd.time.$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$ctimep_TMPDIR" ]]; do
            ctimep_TMPDIR="$PWD/.bash.cmd.time.$(printf '%X' ${RANDOM}${RANDOM:1})"
        done   
        mkdir -p "$ctimep_TMPDIR" || ctimep_TMPDIR=''
    }

     [[ "$ctimep_TMPDIR" ]] || {
         printf '\nERROR: could not create a tmpdir under /dev/shm nor /tmp nor PWD (%s). \nPlease ensure you have requisite write permissions in one of these directories. ABORTING\n\n' "$PWD"
         return 1
    }
    
    #ctimep_LOGFILE="${ctimep_TMPDIR}"/time.ALL

# define helper functions
_ctimep_getTimeDiff () {
## returns the time difference between 2 $EPOCHREALTIME times
    local d d6;
    printf -v d '%.07d' $(( ${2//./} - ${1//./} ));
    d6=$(( ${#d} - 6 ));
    printf '%s.%s\n' "${d:0:$d6}" "${d:$d6}"
};

_ctimep_printTimeDiff() {
## prints a time to the log file
# 6 inputs: $BASHPID $BASH_SUBSHELL $LINENO $BASH_COMMAND pathToStartTimeFile pathToStopTimeFile
# NOTE: start/stop times sare recorded in tmpfiles (not variables) to avoid potential variable name conflicts
    local tStart tEnd
    
    [[ "${4}" ]] && tStart="${4}" || { [[ -f "${ctimep_TMPDIR}/.run.time.start.last" ]] && read -r tStart <"${ctimep_TMPDIR}/.run.time.start.last"; }
    
    [[ "${5}" ]] && tEnd="${5}" || tEnd="${EPOCHREALTIME}"

    [[ $tStart ]] || {
    printf '[ %s {%s} ]  %s:  ERROR ( ??? --> %s ) <<--- { %s }\n' "$1" "$2" "$3" "$tEnd" "${6//$'\n'/'$'"'"'\n'"'"}" 
        return 1
    }
    
    printf '[ %s {%s} ]  %s:  %s sec  ( %s --> %s ) <<--- { %s }\n' "$1" "$2" "$3" "$(_ctimep_getTimeDiff "$tStart" "$tEnd")" "$tStart" "$tEnd" "${6//$'\n'/'$'"'"'\n'"'"}" 
}

    export -f _ctimep_getTimeDiff
    export -f _ctimep_printTimeDiff    
    export ctimep_TMPDIR="${ctimep_TMPDIR}"

    # setup a string with the command to run
    # if stdin isnt a terminal then pass it to whatever is being run / time profiled
    if [[ -t 0 ]]; then
        runCmd="${@}"
    else
        runCmd="cat | { ${@}; }"
    fi

# generate the code for a wrapper function (runFunc) that wraps around whatever we are running / time profiling.
# this will setup a DEBUG trap to measure runtime from every command, then will run the specified code.
# the source code is generated and then sourced (instead of directly defined) so that things like the tmpdir/logfile path are hardcoded.
# this allows ctimep to run without adding any new (and potengtially conflicting) variables to the code being run / time profiled.
runFuncSrc="runFunc () (    
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
[ PID {SHELL.NESTING} ]  LINENO:  RUNTIME  (TSTART --> TSTOP) <<--- { CMD }
----------------------------------------------------------------------------\n\n' \"$runCmd\" \"\$(date)\" \"\$EPOCHREALTIME\" >&\${fd_ctimep};
    echo \"\$EPOCHREALTIME\" > \"$ctimep_TMPDIR\"/.run.time.start.last;
    local ctimep_STARTTIME ctimep_ENDTIME ctimep_BASH_COMMAND_PREV ctimep_LINENO_PREV ctimep_BASHPID_PREV
    ctimep_BASHPID_PREV=\"\$BASHPID\"
    set -T;
    trap '[[ \"\$ctimep_BASHPID_PREV\" == \"\$BASH_PID\" ]] || { declare +g -I ctimep_STARTTIME ctimep_ENDTIME ctimep_BASH_COMMAND_PREV ctimep_LINENO_PREV ctimep_BASHPID_PREV; ctimep_BASHPID_PREV="\$BASHPID"; };
ctimep_ENDTIME=\"\$EPOCHREALTIME\";
_ctimep_printTimeDiff \"\$BASHPID\"  \"\${SHLVL}.\${BASH_SUBSHELL}\" \"\$ctimep_LINENO_PREV\" \"\$ctimep_STARTTIME\" \"\$ctimep_ENDTIME\" \"\$ctimep_BASH_COMMAND_PREV\" >&\${fd_ctimep};
ctimep_BASH_COMMAND_PREV=\"\$BASH_COMMAND\";
ctimep_LINENO_PREV=\"\$LINENO\"
ctimep_STARTTIME=\"\$EPOCHREALTIME\";
echo \"\$ctimep_STARTTIME\" >\"${ctimep_TMPDIR}\"/.run.time.start.last;' DEBUG;

${runCmd}

trap - DEBUG

) {fd_ctimep}>\"${ctimep_TMPDIR}\"/time.ALL"

# source the wrapper function we just generated
eval "${runFuncSrc}"

# source it again by using declare -f in a command substitution
# this may seem silly because it IS silly...but, it makes $LINENO give meaningful line numbers in the DEBUG trap
. <(declare -f runFunc)

runFunc

printf '\n\nThe code being time profiled has finished running!\nctimep will now process the logged timing data.\n\n' >&2

# get lists of unique commands run (unique combinations of pid + subshell level in the logged data
mapfile -t uniq_pids < <(grep -E '^\[ [0-9]+ \{[0-9\.]+\} \]' "${ctimep_TMPDIR}/time.ALL" 2>/dev/null | sed -E s/'^\[ ([0-9]+) \{([0-9]+\.[0-9]+)\} \] .*$'/'\1_\2'/ | sort -u)

tSumAllAll0=0
for p in "${uniq_pids[@]}"; do
    # print header with PID and shell nesting level
    printf 'PID:        \t%s\nNESTING LVL:\t%s\n\n' "${p%%_*}" "${p##*_}" >"${ctimep_TMPDIR}/time.$p"
    # seperate out the data for each pid and save it in a file called time.<pid>
    grep -E '^\[ '"${p%%_*}"' \{'"${p##*_}"'\} \]' "${ctimep_TMPDIR}/time.ALL" 2>/dev/null | sed -E s/'^\[ [0-9]+ \{[0-9\.]+\} \] +'// >>"${ctimep_TMPDIR}/time.$p"

    # find the unique commands (pid + subshell_lvl + line number + cmd) from just this pid/subshell_lvl
    mapfile -t uniq_lines_pid < <(grep -v -E '^((PID)|(NESTING)|([0-9]+\:  ERROR)|$)' 2>/dev/null <"${ctimep_TMPDIR}/time.$p" | sed -E 's/:[^<]+<<\-\-\- /:/' | sort -u)
    outCur=()
    kk=0
    tSumAll0=0
    # for each unique command run by this unique command, pull out the run count and pull out the run times and sum them together
    # print a line to the time.combined.<pid> file vcontaining the run count and the combined run time for that command
    # also, keep track of total run time for this PID
    for l in "${uniq_lines_pid[@]}"; do
        [[ $l ]] || continue
        mapfile -t linesCmdCur < <(grep -F "${l#*:}" "${ctimep_TMPDIR}/time.$p" 2>/dev/null | grep -E '^'"${l%%:*}" 2>/dev/null)
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
    printf -v outCur0 '\n\nTOTAL TIME FOR PID %s {%s}: %s.%s sec\n\n\n' "${p%_*}" "${p#*_}" "${tSumAll:0:$t6}" "${tSumAll:$t6}"
    outCur+=("${outCur0}")
    printf '%s\n' "${outCur[@]}" | sort -g -k1 >"${ctimep_TMPDIR}"/time.combined.$p
done

printf -v tSumAllAll '%.07d' "$tSumAllAll0"
t6=$(( ${#tSumAllAll} - 6 ))


printf '
The following time profile is seperated by process ID (pid). 
For each pid, the time for each line has been combined into a single time.
For example:     <#>:  T sec <<--- (Nx) { cmd }     indicates that: 
For the PID / [sub]shell nesting listed at the top of this group, at line number <#>, cmd was run N times, which had a combined run time of T seconds

TOTAL COMBINED RUN TIME: %s.%s SECONDS

' "${tSumAllAll:0:$t6}" "${tSumAllAll:$t6}" >"${ctimep_TMPDIR}"/time.combined.ALL
cat "${ctimep_TMPDIR}"/time.combined.[0-9]* | sed -z -E s/'\n{3,}'/'\n\n\n'/g >> "${ctimep_TMPDIR}"/time.combined.ALL
printf '\n\nAdditional time profiles, including non-combined ones that show individual command runtimes, can be found under:\n    %s\n\n' "${ctimep_TMPDIR}" >>"${ctimep_TMPDIR}"/time.combined.ALL
cat "${ctimep_TMPDIR}"/time.combined.ALL >&2

export -n ctimep_TMPDIR
export -nf _ctimep_getTimeDiff
export -nf _ctimep_printTimeDiff  
#\rm -f "${ctimep_TMPDIR}"/.bash.cmd.time.*
#if ! [[  "${ctimep_TMPDIR}" == "$PWD" ]] && { { shopt nullglob &>/dev/null && [[ -z $(printf '%s' "${ctimep_TMPDIR}"/*) ]]; } || { ! shopt nullglob &>/dev/null && [[ "$(printf '%s' "${ctimep_TMPDIR}"/*)" == "${ctimep_TMPDIR}"'/*' ]]; }; }; then 
#    \rm -r "${ctimep_TMPDIR}"
#fi
    
)
