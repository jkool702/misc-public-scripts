bashCmdTime() (
    bashCmdTime_TMPDIR=''
    
    [[ -d /dev/shm ]] && { 
        bashCmdTime_TMPDIR=/dev/shm/.bash.cmd.time."$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$bashCmdTime_TMPDIR" ]]; do
            bashCmdTime_TMPDIR=/dev/shm/.bash.cmd.time."$(printf '%X' ${RANDOM}${RANDOM:1})"
        done
        mkdir -p "$bashCmdTime_TMPDIR" && export bashCmdTime_TMPDIR="$bashCmdTime_TMPDIR" || bashCmdTime_TMPDIR=''
    }
    
    [[ "$bashCmdTime_TMPDIR" ]] || {
        bashCmdTime_TMPDIR=/tmp/.bash.cmd.time."$(printf '%X' ${RANDOM}${RANDOM:1})"
        until ! [[ -d "$bashCmdTime_TMPDIR" ]]; do
            bashCmdTime_TMPDIR=/tmp/.bash.cmd.time."$(printf '%X' ${RANDOM}${RANDOM:1})"
        done        
        mkdir -p "$bashCmdTime_TMPDIR" && export bashCmdTime_TMPDIR="$bashCmdTime_TMPDIR" || bashCmdTime_TMPDIR=''
    }
    
    [[ "$bashCmdTime_TMPDIR" ]] || {
        bashCmdTime_TMPDIR="$PWD"
        export bashCmdTime_TMPDIR="$PWD"
    }
    
    [[ ${bashCmdTime_LOGFILE} ]] || bashCmdTime_LOGFILE='&2'

   
getTimeDiff () {
        local d d6;
        printf -v d '%.07d' $(( ${2//./} - ${1//./} ));
        d6=$(( ${#d} - 6 ));
        printf '%s.%s\n' "${d:0:$d6}" "${d:$d6}"
};

printTimeDiff() {
    local tStart tEnd
    tStart="$(<"${5}")"
    tEnd="$(<"${6}")"
    printf '[%s] {%s} %s (%s):  %s sec  (%s --> %s)\n' "$1" "$2" "$(( $3 - 10 ))" "$4" "$(getTimeDiff "$tStart" "$tEnd")" "$tStart" "$tEnd"
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
[[ -f \"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.start.\$BASHPID ]] || printf '\"'\"'%s\n'\"'\"' \"$(<\"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.start.last)\" >\"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.start.\$BASHPID;
printTimeDiff \"\$BASHPID\" \"\$BASH_SUBSHELL\" \"\$LINENO\" \"\$BASH_COMMAND\" \"${bashCmdTime_TMPDIR}/.bash.cmd.time.start.\$BASHPID\" \"${bashCmdTime_TMPDIR}/.bash.cmd.time.end.\$BASHPID\" >&\${fd_bashCmdTime};
echo \"\$EPOCHREALTIME\" >\"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.start.last;
echo \"\$EPOCHREALTIME\" >\"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.start.\$BASHPID;' DEBUG;

${runCmd}

) {fd_bashCmdTime}>${bashCmdTime_LOGFILE}"
	
eval "${runFuncSrc}"
	
. <(declare -f runFunc)

runFunc

export -n bashCmdTime_TMPDIR
export -nf getTimeDiff
export -nf printTimeDiff  
\rm -f "${bashCmdTime_TMPDIR}"/.bash.cmd.time.*
if ! [[  "${bashCmdTime_TMPDIR}" == "$PWD" ]] && { { shopt nullglob &>/dev/null && [[ -z $(printf '%s' "${bashCmdTime_TMPDIR}"/*) ]]; } || { ! shopt nullglob &>/dev/null && [[ "$(printf '%s' "${bashCmdTime_TMPDIR}"/*)" == "${bashCmdTime_TMPDIR}"'/*' ]]; }; }; then 
    \rm -r "${bashCmdTime_TMPDIR}"
fi
    
)
