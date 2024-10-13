#!/usr/bin/env bash

plock() {
## Pipe LOCK - extremely efficient process locking by writing/reading a single newline to/from a shared anonymous pipe
# 
#     plock [-i] [-p <PIPE_ID>] [-f <PIPE_FD>] [-t <#>] [-x] [-u] [-c] [-v]
#
# # # # # USAGE # # # # #
# 
#     # FIRST PROCESS ONLY
#     plock -i                 # opens a file descriptor to a new anonymous pipe and writes a newline to it
#     plock [-t <#>]           # wait for and aquire lock by reading newline from pipe. if "-t <#>" is given then if lock is not aquired in <#> seconds plock will return 1
#     # < do stuff that requires exclusive access to some resource >
#     plock -u                 # release lock by writing newline back to pipe
#     plock -c                 # close file descriptor to pipe
#
#     # SUBSEQUENT PROCESSES
#     plock -p ${PIPE_ID}      # opens a file descriptor to the pipe with ID $PIPE_ID (that was initialized when the 1st process ran `plock -i`)
#     plock [-t <#>]           # --|
#     # < do stuff >           # --|----> repeat these 3 steps as many times as needed
#     plock -u                 # --|
#     plock -c
#
# NOTE: 3 variables will be added to your current shell that are used by plock:
#     PLOCK_ID: contains the inode number identifying the pipe in procfs
#     PLOCK_FD: contains the open file descriptor number for the pipe
#     PLOCK_HAVELOCK: identifies if this process is currently holding the lock.
#
# # # # # FLAGS # # # # #
#
#     -i|--init|--setup: setup a new anonymouys pipe and open a file descriptor to it. The pipe ID and file descriptor number will be saved in PLOCK_ID and PLOCK_FD
#     -p|--pipe|--inode: open a file descriptor to an existing anonymous pipe defined by its inode number in procfs. The file descriptor number will be saved in PLOCK_FD
#     -f|--fd|--file-descriptor: set the file descriptor to use for accessing the pipe. Overrides and overwrites PLOCK_FD.
#     -e|-x|-l|--exclusive|--lock: wait for and aquire the lock by reading from the anonymous pipe. This is the DEFAULT operation if no other flags speciofying an alternate command are given. 
#     -u|--unlock: release the lonk by writing a newline back into the anonymous pipe. This should ONLY be called after sucessfully aquiring the lock.
#     -o|-c|--close: closes the file descriptor for accessing the anonymous pipe
#     -w|-t|--wait|--timeout <#>: sets a timeout of <#> seconds for waiting for the lock. After this timeout has reached plock will return 1 if it has not yet aquired the lock
#     -v|--verbose: print some additional info to stderr
#
# NOTE: if the '-t <#>' flag is not given, plock will wait indefinately to aquire a lock. For a non-blocking lock, use '-t <#>' with a small (but non-zero) <#>.
#
# DEPENDENCIES: bash, find, procfs
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

local pipeProcPath timeoutStr initFlag openFDFlag closeFDFlag lockFlag unlockFlag userFDFlag

initFlag=false
openFDFlag=false
closeFDFlag=false
lockFlag=false
unlockFlag=false
userFDFlag=false
verboseFlag=false
: "${PLOCK_HAVELOCK:=false}" "${PLOCK_ID:=}" "${PLOCK_FD:=}"
    
until (( $# == 0 )); do
    case "${1}" in
        -i|--init|--setup)
            initFlag=true
            shift 1
        ;;
        
        -p|--pipe|--inode)
            openFDFlag=true
            PLOCK_ID="${2}"
            shift 2
        ;;
        
        -f|--fd|--file-descriptor)
            PLOCK_FD="${2}"
            userFDFlag=true
            shift 2
        ;;
        
        -e|-x|-l|--exclusive|--lock)
            lockFlag=true        
            shift 1
        ;;
        
        -u|--unlock)
            unlockFlag=true        
            shift 1
        
        ;;
        
        -o|-c|--close)
            closeFDFlag=true        
            shift 1
        ;;
        
        -w|-t|--wait|--timeout)
            timeoutStr="-t ${2}"
            shift 2
        ;;
        
        -v|--verbose)
            verboseFlag=true
            shift 1
        ;;
        
        *)
            printf '\nWARNING: ignoring unrecognized input (%s)\n' "${1}" >&2
            shift 1
        ;;
    esac
done

${initFlag} && {
    exec {PLOCK_FD}<><(:)
    read -r -d '' _ _ _ _ _ _ _ PLOCK_ID </proc/self/fdinfo/${PLOCK_FD}
    printf '\n' >&${PLOCK_FD}
    ${verboseFlag} && printf '\nPipe ID: %s\nPipe FD: %s\n' "${PLOCK_ID}" "${PLOCK_FD}" >&2
    return 0
}

${openFDFlag} && {
    PLOCK_FD="$(find -L /proc/self/fd -inum "${PLOCK_ID}" -printf '%f' -quit 2>/dev/null)"
    { [[ ${PLOCK_FD} ]] && [[ -e "/proc/self/fd/${PLOCK_FD}" ]]; } || {
        pipeProcPath="$(find -L /proc/*/fd -inum "${PLOCK_ID}" -print -quit 2>/dev/null)"
        [[ ${pipeProcPath} ]] || {
            printf '\nERROR: could not find pipe with ID %s\n\nABORTING\n' "${PLOCK_ID}" >&2
            return 1
        }
        if ${userFDFlag}; then
            source /proc/self/fd/0 <<<"exec ${PLOCK_FD}<>\"${pipeProcPath}\""
        else
            exec {PLOCK_FD}<>"${pipeProcPath}"
        fi
    }
    ${verboseFlag} && printf '\nPipe ID: %s\nPipe FD: %s\n' "${PLOCK_ID}" "${PLOCK_FD}" >&2
    return 0    
}

{ [[ ${PLOCK_FD} ]] && [[ -e "/proc/self/fd/${PLOCK_FD}" ]]; } || {
    printf '\nERROR: could not find/access file descriptor %s\n\nABORTING\n' "${PLOCK_FD}" >&2
    return 1
}

${unlockFlag} || ${closeFDFlag} || lockFlag=true

if ${lockFlag}; then

    ${PLOCK_HAVELOCK} && {
        printf '\nERROR: the lock has already been aquired by this process and has not been released. \nPlease release the lock before trying to re-aquire it!\n' >&2
        return 1
    }
    read -r -N 1 -u "${PLOCK_FD}" ${timeoutStr} _ || return 1
    PLOCK_HAVELOCK=true
    ${verboseFlag} && printf 'LOCK AQUIRED\n' >&2

elif ${unlockFlag}; then

    ${PLOCK_HAVELOCK} || {
        printf '\nERROR: the lock has not yet been aquired by this process. \nPlease aquire the lock before trying to release it!\n' >&2
        return 1
    }
    printf '\n' >&"${PLOCK_FD}"
    PLOCK_HAVELOCK=false
    ${verboseFlag} && printf 'LOCK RELEASED\n' >&2

elif ${closeFDFlag}; then

    exec {PLOCK_FD}>&-
    ${verboseFlag} && printf 'FILE DESCRIPTOR %s CLOSED\n' "${PLOCK_FD}" >&2
    unset PLOCK_ID PLOCK_FD PLOCK_HAVELOCK

fi

return 0

}
