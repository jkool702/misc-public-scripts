#!/usr/bin/env bash

shopt -s extglob

bashCmdTime() (
    ## efficiently produces an accurate per-command execution time profile for shell scripts and functions using a DEBUG trap
    #
    # USAGE: bashCmdTime _______
    #        [...] | bashCmdTime _______ | [...]
    #
    # NOTES: it is REQUIRED that the shell script/function you are generating the time profile for does NOT use a DEBUG trap ANYWHERE
    #        bashCmdTime works by "hijacking" the DEBUG trap, and if the code alters the DEBUG traop then basgCmdTime will stop working
    #
    # DEPENDENCIES:
    #   1) a recent-ish bash versioin (4.0+ (???) - it needs to support the $EPOCHREALTIME variable)
    #   2) sed, grep, sort, mkdir

    shopt -s extglob

    bashCmdTime_TMPDIR=''
    
    [[ -d /dev/shm ]] && { 
        bashCmdTime_TMPDIR=/dev/shm/.bash.cmd.time."$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$bashCmdTime_TMPDIR" ]]; do
            bashCmdTime_TMPDIR=/dev/shm/.bash.cmd.time."$(printf '%X' ${RANDOM}${RANDOM:1})"
        done
        mkdir -p "$bashCmdTime_TMPDIR" || bashCmdTime_TMPDIR=''
    }
    
    [[ "$bashCmdTime_TMPDIR" ]] || {
        bashCmdTime_TMPDIR=/tmp/.bash.cmd.time."$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$bashCmdTime_TMPDIR" ]]; do
            bashCmdTime_TMPDIR=/tmp/.bash.cmd.time."$(printf '%X' ${RANDOM}${RANDOM:1})"
        done        
        mkdir -p "$bashCmdTime_TMPDIR" || bashCmdTime_TMPDIR=''
    }
    
    [[ "$bashCmdTime_TMPDIR" ]] || {
        bashCmdTime_TMPDIR="$PWD/.bash.cmd.time.$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$bashCmdTime_TMPDIR" ]]; do
            bashCmdTime_TMPDIR="$PWD/.bash.cmd.time.$(printf '%X' ${RANDOM}${RANDOM:1})"
        done   
        mkdir -p "$bashCmdTime_TMPDIR" || bashCmdTime_TMPDIR=''
    }

     [[ "$bashCmdTime_TMPDIR" ]] || {
         printf '\nERROR: could not create a tmpdir under /dev/shm nor /tmp nor PWD (%s). \nPlease ensure you have requisite write permissions in one of these directories. ABORTING\n\n' "$PWD"
         return 1
    }
    
    bashCmdTime_LOGFILE="${bashCmdTime_TMPDIR}"/time.ALL

   
getTimeDiff () {
    local d d6;
    printf -v d '%.07d' $(( ${2//./} - ${1//./} ));
    d6=$(( ${#d} - 6 ));
    printf '%s.%s\n' "${d:0:$d6}" "${d:$d6}"
};

printTimeDiff() {
    local tStart tEnd
    
    [[ -e "${5}" ]] && tStart="$(<"${5}")"
    [[ ${tStart} ]] || tStart="$(<"${5%.*}.last")"
    
    tEnd="$(<"${6}")"
    [[ $tEnd ]] || tEnd="${EPOCHREALTIME}"

    { [[ $tStart ]] && [[ $tEnd ]]; } || return 1
    
    printf '[%s] {%s} %s (%s):  %s sec  (%s --> %s)\n' "$1" "$2" "$3" "${4//$'\n'/'$'"'"'\n'"'"}" "$(getTimeDiff "$tStart" "$tEnd")" "$tStart" "$tEnd"
}
export -f getTimeDiff
export -f printTimeDiff    

    if [[ -t 0 ]]; then
        runCmd="${@}"
    else
        runCmd="cat | { ${@}; }"
    fi
    
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
[PID] {SHELL_DEPTH} LINE (CMD):  RUNTIME  (TSTART --> TSTOP)
------------------------------------------------------------\n\n' \"$runCmd\" \"\$(date)\" \"\$EPOCHREALTIME\" >&\${fd_bashCmdTime};
    echo \"\$EPOCHREALTIME\" > \"$bashCmdTime_TMPDIR\"/.bash.cmd.time.start.last;
    echo \"\$EPOCHREALTIME\" > \"$bashCmdTime_TMPDIR\"/.bash.cmd.time.start.\$BASHPID;
    set -T;
    trap 'echo \"\$EPOCHREALTIME\" >\"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.end.\$BASHPID;
printTimeDiff \"\$BASHPID\" \"\$BASH_SUBSHELL\" \"\$LINENO\" \"\$BASH_COMMAND\" \"${bashCmdTime_TMPDIR}/.bash.cmd.time.start.\$BASHPID\" \"${bashCmdTime_TMPDIR}/.bash.cmd.time.end.\$BASHPID\" >&\${fd_bashCmdTime};
echo \"\$EPOCHREALTIME\" >\"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.start.last;
echo \"\$EPOCHREALTIME\" >\"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.start.\$BASHPID;' DEBUG;

${runCmd}

) {fd_bashCmdTime}>${bashCmdTime_LOGFILE}"
    
eval "${runFuncSrc}"
    
. <(declare -f runFunc)

runFunc

mapfile -t uniq_lines < <(grep -E '^\[[0-9]' "${bashCmdTime_LOGFILE}" | sed -E s/'(^\[[0-9]+\] \{[0-9]+\} [0-9]+) .*$'/'\1'/ | sort -k1,3 -u)
mapfile -t uniq_pids < <(printf '%s\n' "${uniq_lines[@]%% *}" | sort -u | sed -E 's/\[//;s/\]//')

for p in "${uniq_pids[@]}"; do
    grep -E '^\['"$p"  "${bashCmdTime_LOGFILE}" >"${bashCmdTime_TMPDIR}"/time.$p
    mapfile -t uniq_lines_pid < <(printf '%s\n' "${uniq_lines[@]}" | grep -E '^\['"$p")
    : >"${bashCmdTime_TMPDIR}"/time.combined.$p
    for l in "${uniq_lines_pid[@]}"; do
        mapfile -t linesCmdCur < <(grep -F "$l" "${bashCmdTime_TMPDIR}"/time.$p)
        timesCmdCur=("${linesCmdCur[@]##*:  }")
        timesCmdCur=("${timesCmdCur[@]%% sec*}")
        timesCmdCur=("${timesCmdCur[@]//./}")
        tSum="$(IFS='+'; printf '%.07d' "$(( "${timesCmdCur[*]##*(0)}" ))")"
        t6=$(( ${#tSum} - 6 ))
        printf '%s:  %s.%s\n' "${linesCmdCur[0]%%:  *}" "${tSum:0:$t6}" "${tSum:$t6}" >>"${bashCmdTime_TMPDIR}"/time.combined.$p
    done
done

printf '\nVarious time profiles can be found under %s\n\n' "${bashCmdTime_TMPDIR}" >&2

export -n bashCmdTime_TMPDIR
export -nf getTimeDiff
export -nf printTimeDiff  
#\rm -f "${bashCmdTime_TMPDIR}"/.bash.cmd.time.*
#if ! [[  "${bashCmdTime_TMPDIR}" == "$PWD" ]] && { { shopt nullglob &>/dev/null && [[ -z $(printf '%s' "${bashCmdTime_TMPDIR}"/*) ]]; } || { ! shopt nullglob &>/dev/null && [[ "$(printf '%s' "${bashCmdTime_TMPDIR}"/*)" == "${bashCmdTime_TMPDIR}"'/*' ]]; }; }; then 
#    \rm -r "${bashCmdTime_TMPDIR}"
#fi
    
)
