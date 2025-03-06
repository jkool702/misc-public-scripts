#!/usr/bin/env bash

shopt -s extglob

ctimep() (
    ## Command TIME Profile - efficiently produces an accurate per-command execution time profile for shell scripts and functions using a DEBUG trap
    #
    # USAGE: ctimep _______
    #        [...] | ctimep _______ | [...]
    #
    # OUTPUT: 4 types of time profiles will be saved to disk in ctimep's tmpdir directory (a new directory under /dev/shm or /tmp or $PWD - printed to stderr at the end):
    #   time.ALL:                the individual per-command run times for every command reun under any pid. This is generated directly by the DEBUF trap as the code runs
    #   time.<pid>.<#>:          the individual per-command run times for a specific pid at subshell nesting level <#>
    #   time.combined.<pid>.<#>: the combined time and run count for each unique command run by that pid. e.g., if a command runs 5 times in a loop, you will get a line that includes "(5x) <total run time>"
    #   time.combined..ALL:      the time.combined.<pid>.<#> files from all pids combined into a single file.  This is printed to stderr at the end
    #
    # OUTPUT FORMAT: 
    #    for individual cmd profiles: [$PID] {$BASH_SUBSHELL} $LINENO ( $BASH_CMD ):  <run_time>  (<start_time --> <end_time>)
    #    for combined cmd profiles:   [$PID] {$BASH_SUBSHELL} $LINENO ( $BASH_CMD ):  (<run_count>x) <total_run_time> 
    #
    # NOTES: 
    #    It is REQUIRED that the shell script/function you are generating the time profile for does NOT use a DEBUG trap ANYWHERE.
    #    ctimep works by "hijacking" the DEBUG trap, and if the code alters the DEBUG traop then ctimep will stop working.
    #    Scripts using RETURN traps MAY not work as expected. "set -T" is used to propogate the DEBUG trap into shell functions,
    #    which also propogates RETURN traps into shell functions.
    #
    # DEPENDENCIES:
    #    1) a recent-ish bash versioin (4.0+ (???) - it needs to support the $EPOCHREALTIME variable)
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
    
    ctimep_LOGFILE="${ctimep_TMPDIR}"/time.ALL

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
    
    [[ -f "${5}" ]] && tStart="$(<"${5}")"
    [[ ${tStart} ]] || { [[ -f "${5%.*}.last" ]] && tStart="$(<"${5%.*}.last")"; }
    
    [[ -f "${6}" ]] && tEnd="$(<"${6}")"
    [[ $tEnd ]] || tEnd="${EPOCHREALTIME}"

    [[ $tStart ]] || {
        printf '[%s] {%s} %s ( %s ):  ERROR  (??? --> %s)\n' "$1" "$2" "$3" "${4//$'\n'/'$'"'"'\n'"'"}" "$tEnd"
        return 1
    }
    
    printf '[%s] {%s} %s ( %s ):  %s sec  (%s --> %s)\n' "$1" "$2" "$3" "${4//$'\n'/'$'"'"'\n'"'"}" "$(_ctimep_getTimeDiff "$tStart" "$tEnd")" "$tStart" "$tEnd"
}

    export -f _ctimep_getTimeDiff
    export -f _ctimep_printTimeDiff    

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
------------------------------------------------------------
--------------- RUNTIME BREAKDOWN BY COMMAND ---------------
------------------------------------------------------------

COMMAND:
%s

START TIME: 
%s (%s)

FORMAT:
------------------------------------------------------------
[PID] {SUBSHELL_DEPTH} LINE ( CMD ):  RUNTIME  (TSTART --> TSTOP)
------------------------------------------------------------\n\n' \"$runCmd\" \"\$(date)\" \"\$EPOCHREALTIME\" >&\${fd_ctimep};
    echo \"\$EPOCHREALTIME\" > \"$ctimep_TMPDIR\"/.run.time.start.last;
    echo \"\$EPOCHREALTIME\" > \"$ctimep_TMPDIR\"/.run.time.start.\$BASHPID;
    set -T;
    trap 'echo \"\$EPOCHREALTIME\" >\"${ctimep_TMPDIR}\"/.run.time.end.\$BASHPID;
_ctimep_printTimeDiff \"\$BASHPID\" \"\$BASH_SUBSHELL\" \"\$LINENO\" \"\$BASH_COMMAND\" \"${ctimep_TMPDIR}/.run.time.start.\$BASHPID\" \"${ctimep_TMPDIR}/.run.time.end.\$BASHPID\" >&\${fd_ctimep};
echo \"\$EPOCHREALTIME\" >\"${ctimep_TMPDIR}\"/.run.time.start.last;
echo \"\$EPOCHREALTIME\" >\"${ctimep_TMPDIR}\"/.run.time.start.\$BASHPID;' DEBUG;

${runCmd}

) {fd_ctimep}>${ctimep_LOGFILE}"

# source the wrapper function we just generated
eval "${runFuncSrc}"

# source it again by using declare -f in a command substitution
# this may seem silly because it IS silly...but, it makes $LINENO give meaningful line numbers in the DEBUG trap
. <(declare -f runFunc)

runFunc

printf '\n\nThe code being time profiled has finished running!\nctimep will now process the logged timing data.\n\n' >&2

# get lists of unique commands run (unique combinations of pid + subshell level in the logged data
mapfile -t uniq_pids < <(grep -E '^\[[0-9]' "${ctimep_LOGFILE}" | sed -E s/'^\[([0-9]+)\] \{([0-9]+)\} .*$'/'\1.\2'/ | sort -k1,3 -u)

tSumAllAll0=0
for p in "${uniq_pids[@]}"; do
    # seperate out the data for each pid and save it in a file called time.<pid>
    grep -E '^\['"${p%%.*}"'\] \{'"${p##*.}"'\}'  "${ctimep_LOGFILE}" >"${ctimep_TMPDIR}"/time.$p

    # find the unique commands (pid + subshell_lvl + line number + cmd) from just this pid/subshell_lvl
    mapfile -t uniq_lines_pid < <(sed -E s/'\:  [^\:]*$'// <"${ctimep_TMPDIR}"/time.$p | sort -u)
    outCur=()
    kk=0
    tSumAll0=0
    # for each unique command run by this unique command, pull out the run count and pull out the run times and sum them together
    # print a line to the time.combined.<pid> file vcontaining the run count and the combined run time for that command
    # also, keep track of total run time for this PID
    for l in "${uniq_lines_pid[@]}"; do
        mapfile -t linesCmdCur < <(grep -F "$l" "${ctimep_TMPDIR}"/time.$p)
        timesCmdCur=("${linesCmdCur[@]##*:  }")
        timesCmdCur=("${timesCmdCur[@]%% sec*}")
        timesCmdCur=("${timesCmdCur[@]//./}")
        timesCmdCur=("${timesCmdCur[@]//-+(0)/-}")
        tSum0="$(( $(printf '%s + ' "${timesCmdCur[@]##+(0)}") 0 ))"
        (( tSumAll0+=tSum0 ))
        printf -v tSum '%.07d' "$tSum0"
        t6=$(( ${#tSum} - 6 ))
        printf -v outCur[$kk] '%s:  (%sx) %s.%s sec\n' "${linesCmdCur[0]%%:  *}" "${#timesCmdCur[@]}" "${tSum:0:$t6}" "${tSum:$t6}"
    done 
    (( tSumAllAll0+=tSumAll0 ))
    printf -v tSumAll '%.07d' "$tSumAll0"
    t6=$(( ${#tSumAll} - 6 ))
    printf '\n\nTOTAL TIME FOR THIS PID (%s): %s.%s sec\n\n\n' "$p" "${tSumAll:0:$t6}" "${tSumAll:$t6}"
    printf '%s\n' "${outCur[@]}" | sort -g -k3 >"${ctimep_TMPDIR}"/time.combined.$p
done

printf -v tSumAllAll '%.07d' "$tSumAllAll0"
t6=$(( ${#tSumAllAll} - 6 ))


porintf '
The following time profile is seperated by process ID (pid). 
For each pid, the time for each line has been combined into a single time.
For example:    [PID] {S} <#> ( cmd):  (Nx) T seconds     indicates that: 
in process PID (run at subshell depth S) at line number #, cmd was run N times, which had a combined run time of T seconds

TOTAL COMBINED RUN TIME: %s.%s SECONDS

' "${tSumAllAll:0:$t6}" "${tSumAllAll:$t6}" >"${ctimep_TMPDIR}"/time.combined.ALL
cat "${ctimep_TMPDIR}"/time.combined.[0-9]* >> "${ctimep_TMPDIR}"/time.combined.ALL
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
