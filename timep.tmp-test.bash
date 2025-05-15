#!/bin/bash

(                  
declare -a BASHPID_A FUNCNAME_A exN 
set -T; 
exN=(0)
BASH_COMMAND_PREV="$BASH_COMMAND"
FUNCNAME_A[0]="${FUNCNAME[0]:-main}"
FUNCDEPTH_PREV=${#FUNCNAME[@]}
BASHPID_A[${BASH_SUBSHELL}]="${BASHPID}"
BASH_SUBSHELL_PREV="${BASH_SUBSHELL}"
TMPDIR=/dev/shm/.timep
[[ -d "$TMPDIR" ]] && \rm -rf "$TMPDIR"
LOGPATH="${TMPDIR}/.log/${BASHPID}/log"
mkdir -p "${LOGPATH%/log}"
echo "${BASH_SUBSHELL}" >"${TMPDIR}/.log/${BASHPID}"/.subshell.prev
read -r _ _ _ _ PGRP_PREV _ _ TGPID_PREV _ </proc/${BASHPID}/stat

printf_A() {
	local IFS nn
	if (( $# == 0 )); then
	    (( ${#A[@]} > 0 )) || printf "\nERROR - please specify variable to print...default variable A not found\n\n" >&2
		return 1
	else
	    [[ "$1" == 'A' ]] || [[ -z "$1" ]] || declare -n A="$1"
		shift 1
	fi
	if (( $# == 0 )); then
	    IFS='.'
	else
	    IFS="${1:0:1}"
		shift 1
	fi
	if (( $# == 0 )); then
	    printf '%s' "${A[*]}"
	else
	    for nn in "$@"; do
		    printf -v "$nn" '%s' "${A[*]}"
		done
	fi
}

trap ':' EXIT RETURN
declare -a -i LINENO_RUN_COUNT

TSTART=${EPOCHREALTIME}

#BASH_NESTING=("${BASHPID}.${BASH_SUBSHELL}_${FUNCNAME[0]:-main}.${#FUNCNAME[@]}")

trap 'TSTOP="${EPOCHREALTIME}"
if [[ "${FUNCNAME_A[-1]}.${FUNCDEPTH_PREV:-0}" == "${FUNCNAME[0]:-main}.${#FUNCNAME[@]}" ]]; then
	printf '"'"'\nFUNC (%s):  %s'"'"' "${#FUNCNAME[@]}" "${FUNCNAME[0]:-main}"
else
	if (( ${FUNCDEPTH_PREV:-0} > ${#FUNCNAME[@]} )); then
	    unset "exN[-1]" "FUNCNAME_A[-1]"
	    printf '"'"'\nFUNC (-):  %s -> %s'"'"' "${FUNCNAME_A[-1]}.${FUNCDEPTH_PREV:-0}" "${FUNCNAME[0]:-main}.${#FUNCNAME[@]}" 
	else
	    LOGPATH="${TMPDIR}/.log/${BASHPID}/"$(IFS='"'"'.'"'"'; printf '"'"'%s'"'"' "${exN[*]}")"/log"
	    mkdir -p "${LOGPATH%/log}"
            (( exN[-1] = exN[-1]  + 1 ))
	    exN+=(0); 
	    printf '"'"'\nFUNC (+):  %s -> %s'"'"' "${FUNCNAME_A[-1]}.${FUNCDEPTH_PREV:-0}" "${FUNCNAME[0]:-main}.${#FUNCNAME[@]}" 
	    FUNCNAME_A+=("${FUNCNAME[0]:-main}")
	fi
	FUNCDEPTH_PREV="${#FUNCNAME[@]}"
fi
if [[ "${BASHPID_A[${BASH_SUBSHELL_PREV}]}" != "${BASHPID}" ]] || (( BASH_SUBSHELL > BASH_SUBSHELL_PREV )); then
    read -r _ _ _ _ PGRP _ _ TGPID _ </proc/${BASHPID}/stat
    if [[ "${PGRP:-${TGPID}]}" != "${PGRP_PREV:-${TGPID_PREV}]}" ]]; then
        BASHPID_A=()
	FUNCNAME_A=()
        exN=(1)
        FUNCNAME_A[${#FUNCNAME[@]}]="${FUNCNAME[0]:-main}"
        LOGPATH="${TMPDIR}/.log/${BASHPID}/log"
        mkdir -p "${LOGPATH}"
        echo "${BASH_SUBSHELL}" >"${LOGPATH}".subshell.prev
    fi
    BASHPID_A[${BASH_SUBSHELL}]="${BASHPID}"
fi
[[ -f "${LOGPATH}".exN ]] && {
    mapfile -t -d '"''"' exN <"${LOGPATH}".exN 
    \rm -f "${LOGPATH}".exN
}
(( exN[-1] = exN[-1]  + 1 ))
(( ${#BASHPID_A[@]} > 1 )) && printf '"'"'%s\0'"'"' "${exN[@]}" >"${LOGPATH}".exN
printf '"'"'\nCOMMAND:  %s --> %s\nPID:  %s\nexec/line number: %s, %s\n\n'"'"' "$BASH_COMMAND_PREV" "$BASH_COMMAND" "$(IFS='"'"'>'"'"'; printf '"'"'%s'"'"' "${BASHPID_A[*]}")"   "$(IFS='"'"'.'"'"'; printf '"'"'%s'"'"' "${exN[*]}")" $LINENO; 
BASH_COMMAND_PREV="$BASH_COMMAND"; ' DEBUG; 

echo hi
echo hi0 | cat | { sleep 1;  cat; } |  tee
( 
echo hi1
echo hi2 | cat | { sleep 1 && cat; } |  tee
)
ff() {
echo hi3
echo hi4 | cat | { sleep 1; cat; } |  tee
}
ff
(
ff
)
ff & 
)

: <<'EOF'
NESTING (1):  1494992.1_main.0
COMMAND:  BASH_COMMAND_PREV="$BASH_COMMAND" --> echo hi
exec/line number: 1, 436

hi

NESTING (1):  1494992.1_main.0
COMMAND:  echo hi --> echo hi0
exec/line number: 2, 437


NESTING (1):  1494992.1_main.0
COMMAND:  echo hi0 --> cat
exec/line number: 3, 437


NESTING (1):  1494992.1_main.0
COMMAND:  cat --> tee
exec/line number: 4, 437


NESTING (+):  1494992.1_main.0 -> 1494998.2_main.0
COMMAND:  cat --> sleep 1
exec/line number: 4.1, 437


NESTING (2):  1494998.2_main.0
COMMAND:  sleep 1 --> cat
exec/line number: 4.2, 437

hi0

NESTING (+):  1494992.1_main.0 -> 1495009.2_main.0
COMMAND:  tee --> echo hi1
exec/line number: 5.1, 439

hi1

NESTING (2):  1495009.2_main.0
COMMAND:  echo hi1 --> echo hi2
exec/line number: 5.2, 440


NESTING (2):  1495009.2_main.0
COMMAND:  echo hi2 --> cat
exec/line number: 5.3, 440


NESTING (2):  1495009.2_main.0
COMMAND:  cat --> tee
exec/line number: 5.4, 440


NESTING (+):  1495009.2_main.0 -> 1495015.3_main.0
COMMAND:  cat --> sleep 1
exec/line number: 5.4.1, 440


NESTING (3):  1495015.3_main.0
COMMAND:  sleep 1 --> cat
exec/line number: 5.4.2, 440

hi2

NESTING (1):  1494992.1_main.0
COMMAND:  tee --> ff
exec/line number: 5, 446


NESTING (+):  1494992.1_main.0 -> 1494992.1_ff.1
COMMAND:  ff --> ff
exec/line number: 6.1, 14


NESTING (2):  1494992.1_ff.1
COMMAND:  ff --> echo hi3
exec/line number: 6.2, 1

hi3

NESTING (2):  1494992.1_ff.1
COMMAND:  echo hi3 --> echo hi4
exec/line number: 6.3, 1


NESTING (2):  1494992.1_ff.1
COMMAND:  echo hi4 --> cat
exec/line number: 6.4, 1


NESTING (2):  1494992.1_ff.1
COMMAND:  cat --> tee
exec/line number: 6.5, 1


NESTING (+):  1494992.1_ff.1 -> 1495029.2_ff.1
COMMAND:  cat --> sleep 1
exec/line number: 6.5.1, 1


NESTING (3):  1495029.2_ff.1
COMMAND:  sleep 1 --> cat
exec/line number: 6.5.2, 1

hi4

NESTING (2):  1494992.1_ff.1
COMMAND:  tee --> tee
exec/line number: 6.6, 1


NESTING (-):  1494992.1_ff.1 -> 1494992.1_main.0
COMMAND:  tee --> ff
exec/line number: 6, 448


NESTING (+):  1494992.1_main.0 -> 1495037.2_ff.1
COMMAND:  ff --> ff
exec/line number: 7.1, 14


NESTING (2):  1495037.2_ff.1
COMMAND:  ff --> echo hi3
exec/line number: 7.2, 1

hi3

NESTING (2):  1495037.2_ff.1
COMMAND:  echo hi3 --> echo hi4
exec/line number: 7.3, 1


NESTING (2):  1495037.2_ff.1
COMMAND:  echo hi4 --> cat
exec/line number: 7.4, 1


NESTING (2):  1495037.2_ff.1
COMMAND:  cat --> tee
exec/line number: 7.5, 1


NESTING (+):  1495037.2_ff.1 -> 1495045.3_ff.1
COMMAND:  cat --> sleep 1
exec/line number: 7.5.1, 1


NESTING (3):  1495045.3_ff.1
COMMAND:  sleep 1 --> cat
exec/line number: 7.5.2, 1

hi4

NESTING (2):  1495037.2_ff.1
COMMAND:  tee --> tee
exec/line number: 7.6, 1


NESTING (-):  1494992.1_ff.1 -> 1494992.1_main.0
COMMAND:  tee --> ff
exec/line number: 6, 450


NESTING (1):  1494992.1_main.0
NESTING (+):  1494992.1_main.0 -> 1495054.2_ff.1
COMMAND:  ff --> ff
exec/line number: 7, 14


COMMAND:  ff --> ff
exec/line number: 7.1, 14


NESTING (2):  1495054.2_ff.1root@localhost:/mnt/ramdisk# 
COMMAND:  ff --> echo hi3
exec/line number: 7.2, 1

hi3

NESTING (2):  1495054.2_ff.1
COMMAND:  echo hi3 --> echo hi4
exec/line number: 7.3, 1


NESTING (2):  1495054.2_ff.1
COMMAND:  echo hi4 --> cat
exec/line number: 7.4, 1


NESTING (2):  1495054.2_ff.1
COMMAND:  cat --> tee
exec/line number: 7.5, 1


NESTING (+):  1495054.2_ff.1 -> 1495062.3_ff.1
COMMAND:  cat --> sleep 1
exec/line number: 7.5.1, 1


NESTING (3):  1495062.3_ff.1
COMMAND:  sleep 1 --> cat
exec/line number: 7.5.2, 1

hi4

NESTING (2):  1495054.2_ff.1
COMMAND:  tee --> tee
exec/line number: 7.6, 1

NESTING (1):  1494992.1_main.0
COMMAND:  BASH_COMMAND_PREV="$BASH_COMMAND" --> echo hi
exec/line number: 1, 436

hi

NESTING (1):  1494992.1_main.0
COMMAND:  echo hi --> echo hi0
exec/line number: 2, 437


NESTING (1):  1494992.1_main.0
COMMAND:  echo hi0 --> cat
exec/line number: 3, 437


NESTING (1):  1494992.1_main.0
COMMAND:  cat --> tee
exec/line number: 4, 437


NESTING (+):  1494992.1_main.0 -> 1494998.2_main.0
COMMAND:  cat --> sleep 1
exec/line number: 4.1, 437


NESTING (2):  1494998.2_main.0
COMMAND:  sleep 1 --> cat
exec/line number: 4.2, 437

hi0

NESTING (+):  1494992.1_main.0 -> 1495009.2_main.0
COMMAND:  tee --> echo hi1
exec/line number: 5.1, 439

hi1

NESTING (2):  1495009.2_main.0
COMMAND:  echo hi1 --> echo hi2
exec/line number: 5.2, 440


NESTING (2):  1495009.2_main.0
COMMAND:  echo hi2 --> cat
exec/line number: 5.3, 440


NESTING (2):  1495009.2_main.0
COMMAND:  cat --> tee
exec/line number: 5.4, 440


NESTING (+):  1495009.2_main.0 -> 1495015.3_main.0
COMMAND:  cat --> sleep 1
exec/line number: 5.4.1, 440


NESTING (3):  1495015.3_main.0
COMMAND:  sleep 1 --> cat
exec/line number: 5.4.2, 440

hi2

NESTING (1):  1494992.1_main.0
COMMAND:  tee --> ff
exec/line number: 5, 446


NESTING (+):  1494992.1_main.0 -> 1494992.1_ff.1
COMMAND:  ff --> ff
exec/line number: 6.1, 14


NESTING (2):  1494992.1_ff.1
COMMAND:  ff --> echo hi3
exec/line number: 6.2, 1

hi3

NESTING (2):  1494992.1_ff.1
COMMAND:  echo hi3 --> echo hi4
exec/line number: 6.3, 1


NESTING (2):  1494992.1_ff.1
COMMAND:  echo hi4 --> cat
exec/line number: 6.4, 1


NESTING (2):  1494992.1_ff.1
COMMAND:  cat --> tee
exec/line number: 6.5, 1


NESTING (+):  1494992.1_ff.1 -> 1495029.2_ff.1
COMMAND:  cat --> sleep 1
exec/line number: 6.5.1, 1


NESTING (3):  1495029.2_ff.1
COMMAND:  sleep 1 --> cat
exec/line number: 6.5.2, 1

hi4

NESTING (2):  1494992.1_ff.1
COMMAND:  tee --> tee
exec/line number: 6.6, 1


NESTING (-):  1494992.1_ff.1 -> 1494992.1_main.0
COMMAND:  tee --> ff
exec/line number: 6, 448


NESTING (+):  1494992.1_main.0 -> 1495037.2_ff.1
COMMAND:  ff --> ff
exec/line number: 7.1, 14


NESTING (2):  1495037.2_ff.1
COMMAND:  ff --> echo hi3
exec/line number: 7.2, 1

hi3

NESTING (2):  1495037.2_ff.1
COMMAND:  echo hi3 --> echo hi4
exec/line number: 7.3, 1


NESTING (2):  1495037.2_ff.1
COMMAND:  echo hi4 --> cat
exec/line number: 7.4, 1


NESTING (2):  1495037.2_ff.1
COMMAND:  cat --> tee
exec/line number: 7.5, 1


NESTING (+):  1495037.2_ff.1 -> 1495045.3_ff.1
COMMAND:  cat --> sleep 1
exec/line number: 7.5.1, 1


NESTING (3):  1495045.3_ff.1
COMMAND:  sleep 1 --> cat
exec/line number: 7.5.2, 1

hi4

NESTING (2):  1495037.2_ff.1
COMMAND:  tee --> tee
exec/line number: 7.6, 1


NESTING (-):  1494992.1_ff.1 -> 1494992.1_main.0
COMMAND:  tee --> ff
exec/line number: 6, 450


NESTING (1):  1494992.1_main.0
NESTING (+):  1494992.1_main.0 -> 1495054.2_ff.1
COMMAND:  ff --> ff
exec/line number: 7, 14


COMMAND:  ff --> ff
exec/line number: 7.1, 14


NESTING (2):  1495054.2_ff.1root@localhost:/mnt/ramdisk# 
COMMAND:  ff --> echo hi3
exec/line number: 7.2, 1

hi3

NESTING (2):  1495054.2_ff.1
COMMAND:  echo hi3 --> echo hi4
exec/line number: 7.3, 1


NESTING (2):  1495054.2_ff.1
COMMAND:  echo hi4 --> cat
exec/line number: 7.4, 1


NESTING (2):  1495054.2_ff.1
COMMAND:  cat --> tee
exec/line number: 7.5, 1


NESTING (+):  1495054.2_ff.1 -> 1495062.3_ff.1
COMMAND:  cat --> sleep 1
exec/line number: 7.5.1, 1


NESTING (3):  1495062.3_ff.1
COMMAND:  sleep 1 --> cat
exec/line number: 7.5.2, 1

hi4

NESTING (2):  1495054.2_ff.1
COMMAND:  tee --> tee
exec/line number: 7.6, 1

EOF



# new mini test

(
set -T; trap 'echo "child died ($REPLY)" >&$fd' CHLD
trap 'printf '"'"'(EXIT): (%s.%s): %s\n'"'"' "$BASHPID" "$BASH_SUBSHELL" "$BASH_COMMAND_PREV"; :' EXIT
trap_exit='printf '"'"'(EXIT): (%s.%s): %s\n'"'"' "$BASHPID" "$BASH_SUBSHELL" "$BASH_COMMAND_PREV"; :'
BASH_COMMAND_PREV='none'
printf '\n\nparent PID is %s\n\n\n' "${BASHPID}.${BASH_SUBSHELL}"
trap 'trap -- KILL; trap '"'${trap_exit//"'"/"'"'"'"'"'"'"'"}'"' EXIT; printf '"'"'(DEBUG): (%s.%s): %s\n'"'"' "$BASHPID" "$BASH_SUBSHELL" "$BASH_COMMAND"; BASH_COMMAND_PREV="$BASH_COMMAND"' DEBUG
printf '(%s.%s): %s\n' "$BASHPID" "$BASH_SUBSHELL" 1 | cat | { tee; printf '(%s.%s): %s\n' "$BASHPID" "$BASH_SUBSHELL" 2 >&${fd}; sleep 5; }
printf '\n\n\n' >&2
{ printf '(%s.%s): %s\n' "$BASHPID" "$BASH_SUBSHELL" 1; } | cat | { tee; printf '(%s.%s): %s\n' "$BASHPID" "$BASH_SUBSHELL" 2 >&${fd}; sleep 5; }
) {fd}>&2


: <<'EOF'
parent PID is 107330.1


(DEBUG): (107330.1): printf '(%s.%s): %s\n' "$BASHPID" "$BASH_SUBSHELL" 1
(DEBUG): (107330.1): cat
(DEBUG): (107333.2): tee
(107331.1): 1
(DEBUG): (107333.2): printf '(%s.%s): %s\n' "$BASHPID" "$BASH_SUBSHELL" 2 >&${fd}
(107333.2): 2
(DEBUG): (107333.2): sleep 5
(DEBUG): (107333.2): sleep 5
(EXIT): (107333.2): sleep 5
(DEBUG): (107333.2): sleep 5
(DEBUG): (107330.1): cat
child died ()
(DEBUG): (107330.1): cat
child died ()
(DEBUG): (107330.1): cat
child died ()
(DEBUG): (107330.1): printf '\n\n\n' 1>&2



(DEBUG): (107330.1): cat
(DEBUG): (107338.2): tee
(DEBUG): (107336.2): printf '(%s.%s): %s\n' "$BASHPID" "$BASH_SUBSHELL" 1
(107336.2): 1
(DEBUG): (107336.2): printf '(%s.%s): %s\n' "$BASHPID" "$BASH_SUBSHELL" 1
(EXIT): (107336.2): printf '(%s.%s): %s\n' "$BASHPID" "$BASH_SUBSHELL" 1
(DEBUG): (107336.2): printf '(%s.%s): %s\n' "$BASHPID" "$BASH_SUBSHELL" 1
(DEBUG): (107338.2): printf '(%s.%s): %s\n' "$BASHPID" "$BASH_SUBSHELL" 2 >&${fd}
(107338.2): 2
(DEBUG): (107338.2): sleep 5
(DEBUG): (107338.2): sleep 5
(EXIT): (107338.2): sleep 5
(DEBUG): (107338.2): sleep 5
(DEBUG): (107330.1): cat
child died ()
(DEBUG): (107330.1): cat
child died ()
(DEBUG): (107330.1): cat
child died ()
(DEBUG): (107330.1): cat
(EXIT): (107330.1): cat
(DEBUG): (107330.1): cat
EOF
