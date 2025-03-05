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
    
    [[ ${bashCmdTime_logfile} ]] || bashCmdTime_logfile='&2'

   
getTimeDiff () {
        local d d6;
        printf -v d '%.07d' $(( ${2//./} - ${1//./} ));
        d6=$(( ${#d} - 6 ));
        printf '%s.%s\n' "${d:0:$d6}" "${d:$d6}"
};

printTimeDiff() {
    local tStart tEnd
    tStart="$(<"${4}")"
    tEnd="$(<"${5}")"
    printf '[%s] %s (%s): \t%s sec    (%s --> %s)\n' "$1" "$(( $2 - 10 ))" "$3" "$(getTimeDiff "$tStart" "$tEnd")" "$tStart" "$tEnd"
}
export -f getTimeDiff
export -f printTimeDiff    

   if [[ -t 0 ]]; then
        runCmd="${@}"
    else
        crunCmd="cat | { ${@}; }"
    fi
    
runFuncSrc="runFunc () (    
    echo \"\$EPOCHREALTIME\" > \"$bashCmdTime_TMPDIR\"/.bash.cmd.time.start.last;
    echo \"\$EPOCHREALTIME\" > \"$bashCmdTime_TMPDIR\"/.bash.cmd.time.start.\$BASHPID;
    set -T;
    trap 'echo \"\$EPOCHREALTIME\" >\"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.end.\$BASHPID;
[[ -f \"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.start.\$BASHPID ]] || printf '\"'\"'%s\n'\"'\"' \"$(<\"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.start.last)\" >\"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.start.\$BASHPID;
printTimeDiff \"\$BASHPID\" \"\$LINENO\" \"\$BASH_COMMAND\" \"${bashCmdTime_TMPDIR}/.bash.cmd.time.start.\$BASHPID\" \"${bashCmdTime_TMPDIR}/.bash.cmd.time.end.\$BASHPID\" >&\${fd_bashCmdTime};
echo \"\$EPOCHREALTIME\" >\"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.start.last;
echo \"\$EPOCHREALTIME\" >\"${bashCmdTime_TMPDIR}\"/.bash.cmd.time.start.\$BASHPID;' DEBUG;
"

   if [[ -t 0 ]]; then
        runFuncSrc+="
${@}

) {fd_bashCmdTime}>${bashCmdTime_logfile}"
    else
        runFuncSrc+="
cat | {
${@}
}

) {fd_bashCmdTime}>${bashCmdTime_logfile}"
    fi
	
eval "${runFuncSrc}"
	
. <(declare -f runFunc)

runFunc

export -n bashCmdTime_TMPDIR
export -nf getTimeDiff
export -nf printTimeDiff  
\rm -f "${bashCmdTime_TMPDIR}"/.bash.cmd.time.*
)
