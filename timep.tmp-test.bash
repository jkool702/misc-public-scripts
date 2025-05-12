#!/bin/bash

(                                        
set -T; 
exN=(1)
BASH_COMMAND_PREV="$BASH_COMMAND"
FUNCNAME_PREV=(${FUNCNAME[@]}); 

BASH_NESTING=("${BASHPID}.${BASH_SUBSHELL}_${FUNCNAME[0]:-main}.${#FUNCNAME[@]}")

trap ':' EXIT RETURN

trap 'if [[ "${BASH_NESTING[-1]}" == "${BASHPID}.${BASH_SUBSHELL}_${FUNCNAME[0]:-main}.${#FUNCNAME[@]}" ]]; then
	printf '"'"'\nNESTING (%s):  %s'"'"' "${#BASH_NESTING[@]}" "${BASH_NESTING[-1]}"
else
	if (( ${BASH_NESTING[-1]##*.} > ${#FUNCNAME[@]} )); then
	    unset "exN[-1]"
	    printf '"'"'\nNESTING (-):  %s -> %s'"'"' "${BASH_NESTING[-1]}" "${BASH_NESTING[-2]}" 
	    unset "BASH_NESTING[-1]"
	else
	    exN+=(1); 
	    BASH_NESTING+=("${BASHPID}.${BASH_SUBSHELL}_${FUNCNAME[0]:-main}.${#FUNCNAME[@]}");
	    printf '"'"'\nNESTING (+):  %s -> %s'"'"' "${BASH_NESTING[-2]}"  "${BASH_NESTING[-1]}"
	fi
fi
printf '"'"'\nCOMMAND:  %s --> %s\nexec/line number: %s, %s\n\n'"'"' "$BASH_COMMAND_PREV" "$BASH_COMMAND" "$(IFS='"'"'.'"'"'; printf '"'"'%s'"'"' "${exN[*]}")" $LINENO; 
BASH_COMMAND_PREV="$BASH_COMMAND"; 
(( exN[-1] = exN[-1] + 1 ))' DEBUG; 

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
