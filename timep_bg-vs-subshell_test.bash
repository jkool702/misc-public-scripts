```
(
set -T
set -m

: &

read -r _ _ _ _ timep_PARENT_PGID _ _ timep_PARENT_TPID _ </proc/${BASHPID}/stat
timep_CHILD_PGID="$timep_PARENT_PGID"
timep_CHILD_TPID="$timep_PARENT_TPID"

timep_BASHPID_PREV="$BASHPID"
timep_BG_PID_PREV="$!"
timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
timep_SUBSHELL_BASHPID_CUR=''
timep_NEXEC_0=''
timep_NEXEC_A=('0')
timep_NPIDWRAP='0'
timep_BASHPID_STR="${BASHPID}"
timep_FUNCNAME_STR="main"

timep_SIMPLEFORK_NEXT_FLAG=false
timep_SIMPLEFORK_CUR_FLAG=false
timep_SKIP_DEBUG_FLAG=false
timep_NO_PRINT_FLAG=false
timep_IS_FUNC_FLAG_1=false

timep_BASH_COMMAND_PREV=()
timep_NPIPE=()
timep_STARTTIME=()

timep_FNEST=("${#FUNCNAME[@]}")
timep_FNEST_CUR="${#FUNCNAME[@]}"

timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]=''
timep_NPIPE[${timep_FNEST_CUR}]='0'
timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"

ff() { echo "${*}"; }

builtin trap - EXIT RETURN DEBUG

export -p timep_RETURN_TRAP_STR &>/dev/null && export -n timep_RETURN_TRAP_STR

declare -gxr timep_RETURN_TRAP_STR='timep_SKIP_DEBUG_FLAG=true
unset "timep_FNEST[-1]" "timep_NEXEC_A[-1]" "timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]" "timep_NPIPE[${timep_FNEST_CUR}]" "timep_STARTTIME[${timep_FNEST_CUR}]"
timep_NEXEC_0="${timep_NEXEC_0%.*}"
timep_FUNCNAME_STR="${timep_FUNCNAME_STR%.*}"
timep_FNEST_CUR="${timep_FNEST[-1]}"
timep_SKIP_DEBUG_FLAG=false'

export -p timep_DEBUG_TRAP_STR &>/dev/null && export -n timep_DEBUG_TRAP_STR
declare -agxr timep_DEBUG_TRAP_STR=('timep_NPIPE0="${#PIPESTATUS[@]}"
timep_ENDTIME0="${EPOCHREALTIME}"
' '
[[ "$-" == *m* ]] || { 
  printf '"'"'\nWARNING: timep requires job control to be enabled.\n         Running "set +m" is not allowed!\n         Job control will automatically be re-enabled.\n\n'"'"' >&2
  set -m
}
[[ "${BASH_COMMAND}" == trap\ * ]] && {
  timep_SKIP_DEBUG_FLAG=true
  (( timep_FNEST_CUR == ${#FUNCNAME[@]} )) && {
    timep_FNEST_CUR="${#FUNCNAME[@]}"
    timep_FNEST+=("${#FUNCNAME[@]}")
    timep_BASH_COMMAND_PREV+=("${BASH_COMMAND}")
    timep_FUNCNAME_STR+=".trap"
    timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
    timep_NEXEC_A+=("0")
  }
}
${timep_SKIP_DEBUG_FLAG} || {
timep_NPIPE[${timep_FNEST_CUR}]=${timep_NPIPE0}
timep_ENDTIME=${timep_ENDTIME0}
timep_IS_BG_FLAG=false
timep_IS_SUBSHELL_FLAG=false
timep_IS_FUNC_FLAG=false
timep_CMD_TYPE='"''"'
if ${timep_SIMPLEFORK_NEXT_FLAG}; then
  timep_SIMPLEFORK_NEXT_FLAG=false
  timep_SIMPLEFORK_CUR_FLAG=true
else
  timep_SIMPLEFORK_CUR_FLAG=false
fi
if (( timep_BASH_SUBSHELL_PREV == BASH_SUBSHELL )); then
  if (( timep_BG_PID_PREV == $! )); then
    (( timep_FNEST_CUR >= ${#FUNCNAME[@]} )) || {
      timep_NO_PRINT_FLAG=true
      timep_IS_FUNC_FLAG=true
      timep_FNEST+=("${#FUNCNAME[@]}")
    }
  else
    timep_IS_BG_FLAG=true
  fi
else
  timep_IS_SUBSHELL_FLAG=true
  (( BASHPID < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
  timep_SUBSHELL_BASHPID_CUR="$BASHPID"
  builtin trap '"'"':'"'"' EXIT
  read -r _ _ _ _ timep_CHILD_PGID _ _ timep_CHILD_TPID _ </proc/${BASHPID}/stat
  (( timep_CHILD_PGID == timep_PARENT_TPID )) || (( timep_CHILD_PGID == timep_CHILD_TPID )) || {  (( timep_CHILD_PGID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )); } || timep_IS_BG_FLAG=true
fi
if ${timep_IS_SUBSHELL_FLAG} && ${timep_IS_BG_FLAG}; then
  (( timep_CHILD_PGID == BASHPID )) && (( timep_CHILD_TPID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )) && timep_SIMPLEFORK_NEXT_FLAG=true
  timep_CMD_TYPE="BACKGROUND FORK"
elif ${timep_IS_SUBSHELL_FLAG}; then
  timep_CMD_TYPE="SUBSHELL"
elif [[ "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]}" == " (F) "* ]]; then
  timep_CMD_TYPE="FUNCTION (P)"
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]# (F) }"
elif ${timep_IS_BG_FLAG}; then
  timep_CMD_TYPE="SIMPLE FORK"
elif ${timep_IS_FUNC_FLAG_1}; then
  timep_CMD_TYPE="FUNCTION (C)"
  timep_IS_FUNC_FLAG_1=false
else
  timep_CMD_TYPE="NORMAL COMMAND"
fi
if ${timep_IS_SUBSHELL_FLAG}; then
  (( timep_BASH_SUBSHELL_DIFF = BASH_SUBSHELL - timep_BASH_SUBSHELL_PREV ))
  timep_KK=0
        timep_BASHPID_ADD=()
        while (( timep_BASH_SUBSHELL_DIFF > 0 )); do
            (( timep_BASH_SUBSHELL_DIFF-- ))
            case "${timep_KK}" in
                0) timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}]="${BASHPID}" ;;
                *) (( timep_BASH_SUBSHELL_DIFF_0 = timep_BASH_SUBSHELL_DIFF + 1 )); IFS=" " read -r _ _ _ timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}] _ </proc/${timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF_0}]}/stat ;;
            esac
            if (( timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}] == timep_BASHPID_PREV )) || (( timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}] <= 1 )); then
                (( timep_BASH_SUBSHELL_DIFF++ ))
                break
            else
                (( timep_KK++ ))
            fi
            unset "timep_BASH_SUBSHELL_DIFF_0"
        done
        timep_KK="${timep_BASH_SUBSHELL_DIFF}"
             timep_NEXEC_0+=".${timep_NEXEC_A[-1]}[${timep_NPIDWRAP}-${timep_BASHPID_PREV}]"
            timep_NEXEC_A+=(0)
        while (( timep_KK < ( ${#timep_BASHPID_ADD[@]} - 1 ) )); do

            (( timep_BASHPID_ADD[${timep_KK}] < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
            timep_BASHPID_PREV="${timep_BASHPID_ADD[${timep_KK}]}"
            timep_BASHPID_STR+=".${timep_BASHPID_PREV}"
            (( timep_KK++ ))
             timep_NEXEC_0+=".${timep_NEXEC_A[-1]}[${timep_NPIDWRAP}-${timep_BASHPID_PREV}]"
            timep_NEXEC_A+=(0)
        done
            (( timep_BASHPID_ADD[${timep_KK}] < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
            timep_BASHPID_PREV="${timep_BASHPID_ADD[${timep_KK}]}"
        unset "timep_KK" "timep_BASHPID_ADD"
  ${timep_NO_PRINT_FLAG} || printf '"'"'log%s.%s[%s-%s] np: %s  %s  %s  (f:%s %s)  (s:%s %s):  < pid: %s > is a %s\n'"'"' "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_NPIDWRAP}" "${BASHPID}" "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_STARTTIME[${timep_FNEST_CUR}]}" "${timep_ENDTIME}" "${timep_FNEST_CUR}" "${timep_FUNCNAME_STR}" "${BASH_SUBSHELL}" "${timep_BASHPID_STR}" "${BASHPID}" "${timep_CMD_TYPE}" >&${timep_FD}
             timep_BASHPID_STR+=".${timep_BASHPID_PREV}"
             timep_NEXEC_0+=".${timep_NEXEC_A[-1]}[${timep_NPIDWRAP}-${timep_BASHPID_PREV}]"
            timep_NEXEC_A+=(0)
            timep_PARENT_PGID="$timep_CHILD_PGID"
  timep_PARENT_TPID="$timep_CHILD_TPID"
  timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
elif [[ ${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]} ]]; then
  ${timep_SIMPLEFORK_CUR_FLAG} && (( BASHPID < $! )) && timep_CMD_TYPE="SIMPLE FORK *"
  ${timep_NO_PRINT_FLAG} || printf '"'"'log%s.%s[%s-%s] np: %s  %s  %s  (f:%s %s)  (s:%s %s):  < %s > is a %s\n'"'"' "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_NPIDWRAP}" "${BASHPID}" "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_STARTTIME[${timep_FNEST_CUR}]}" "${timep_ENDTIME}" "${timep_FNEST_CUR}" "${timep_FUNCNAME_STR}" "${BASH_SUBSHELL}" "${timep_BASHPID_STR}" "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]@Q}" "${timep_CMD_TYPE}" >&${timep_FD}
  (( timep_NEXEC_A[-1]++ ))
fi
if ${timep_IS_FUNC_FLAG}; then
  timep_FUNCNAME_STR+=".${FUNCNAME[0]}"
  timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
  timep_NEXEC_A+=(0)
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]=" (F) ${BASH_COMMAND}"
  timep_NPIPE[${#FUNCNAME[@]}]="${timep_NPIPE[${timep_FNEST_CUR}]}"
  timep_FNEST_CUR="${#FUNCNAME[@]}"
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${BASH_COMMAND}"
  timep_NO_PRINT_FLAG=false
  timep_IS_FUNC_FLAG_1=true
else
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="$BASH_COMMAND"
fi
timep_BG_PID_PREV="$!"
timep_BASHPID_PREV="$BASHPID"
timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"
}')

export timep_DEBUG_TRAP_STR

export -p -f trap &>/dev/null && export -n -f trap

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap "${trapStr}"':' EXIT ;;
            RETURN)  builtin trap "${trapStr}${timep_RETURN_TRAP_STR}" RETURN ;;
            DEBUG)   builtin trap "${timep_DEBUG_TRAP_STR[0]}${trapStr}${timep_DEBUG_TRAP_STR[1]}" DEBUG ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
}

export -f trap

builtin trap ':' EXIT
builtin trap "${timep_RETURN_TRAP_STR}" RETURN
builtin trap "${timep_DEBUG_TRAP_STR[0]}"$'\n'"${timep_DEBUG_TRAP_STR[1]}" DEBUG


gg() { echo "$*"; ff "$@"; }

{ echo ; } &
{ ( echo A & ); echo B; } &

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &

( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

trap 'echo got USR1; sleep .01' USR1
kill -USR1 $BASHPID
echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done

(
    trap 'echo bye' EXIT
    exit
)

(
    trap 'echo bye' RETURN EXIT
    gg 1
    exit
)

(
    trap 'echo exit' EXIT
    trap 'echo return' RETURN
    gg 1
    exit
)


(
    trap '' RETURN EXIT
    exit
)


(
    trap - EXIT
    exit
)

( ( ( ( echo $BASHPID; ); echo $BASHPID; ); echo $BASHPID; ); echo $BASHPID; ); 

builtin trap - DEBUG EXIT RETURN

) {timep_FD}>&2
```

gives

```
0
log.0[0-14715].0[0-14717] np: 1  1750407852.237741  1750407852.239149  (f:0 main)  (s:2 14715):  < pid: 14717 > is a BACKGROUND FORK

log.0[0-14715] np: 1  1750407852.239516  1750407852.239583  (f:0 main)  (s:1 14715):  < 'echo 0' > is a NORMAL COMMAND
1
log.0[0-14715].0[0-14718].0[0-14719] np: 1  1750407852.237741  1750407852.239507  (f:0 main)  (s:3 14715.14718):  < pid: 14719 > is a BACKGROUND FORK
log.0[0-14715].0[0-14717].0[0-14717] np: 1  1750407852.239987  1750407852.240060  (f:0 main)  (s:2 14715.14717):  < 'echo' > is a NORMAL COMMAND
A
log.0[0-14715].0[0-14718].0[0-14719].0[0-14719] np: 1  1750407852.240467  1750407852.240820  (f:0 main)  (s:3 14715.14718.14719):  < 'echo A' > is a SIMPLE FORK
log.1[0-14715].0[0-14720] np: 1  1750407852.240150  1750407852.240662  (f:0 main)  (s:2 14715):  < pid: 14720 > is a BACKGROUND FORK
2
log.1[0-14715].0[0-14720].0[0-14720] np: 1  1750407852.241465  1750407852.241538  (f:0 main)  (s:2 14715.14720):  < 'echo 2' > is a NORMAL COMMAND
log.1[0-14715] np: 1  1750407852.240150  1750407852.242100  (f:0 main)  (s:1 14715):  < 'echo 1' > is a NORMAL COMMAND
log.0[0-14715].0[0-14718] np: 1  1750407852.237741  1750407852.241684  (f:0 main)  (s:2 14715):  < pid: 14718 > is a BACKGROUND FORK
B
3
log.2[0-14715] np: 1  1750407852.242429  1750407852.242697  (f:0 main)  (s:1 14715):  < 'echo 3' > is a SIMPLE FORK
log.0[0-14715].0[0-14718].0[0-14718] np: 1  1750407852.242570  1750407852.242645  (f:0 main)  (s:2 14715.14718):  < 'echo B' > is a NORMAL COMMAND
4
log.3[0-14715].0[0-14724] np: 1  1750407852.243141  1750407852.243716  (f:0 main)  (s:2 14715):  < pid: 14724 > is a BACKGROUND FORK
5
log.3[0-14715].0[0-14725] np: 1  1750407852.243141  1750407852.243884  (f:0 main)  (s:2 14715):  < pid: 14725 > is a SUBSHELL
6
log.3[0-14715].0[0-14724].0[0-14724] np: 1  1750407852.244565  1750407852.244692  (f:0 main)  (s:2 14715.14724):  < 'echo 5' > is a NORMAL COMMAND
log.3[0-14715].0[0-14725].0[0-14725] np: 1  1750407852.244661  1750407852.244978  (f:0 main)  (s:2 14715.14725):  < 'echo 6' > is a SIMPLE FORK
log.3[0-14715].0[0-14728] np: 1  1750407852.243141  1750407852.246265  (f:0 main)  (s:2 14715):  < pid: 14728 > is a SUBSHELL
8
log.3[0-14715].0[0-14727] np: 1  1750407852.243141  1750407852.246179  (f:0 main)  (s:2 14715):  < pid: 14727 > is a BACKGROUND FORK
7
log.3[0-14715].0[0-14728].0[0-14728] np: 1  1750407852.246788  1750407852.246843  (f:0 main)  (s:2 14715.14728):  < 'echo 8' > is a NORMAL COMMAND
log.3[0-14715].0[0-14727].0[0-14727] np: 1  1750407852.247002  1750407852.247069  (f:0 main)  (s:2 14715.14727):  < 'echo 7' > is a NORMAL COMMAND
log.3[0-14715].0[0-14729] np: 1  1750407852.243141  1750407852.247718  (f:0 main)  (s:2 14715):  < pid: 14729 > is a BACKGROUND FORK
log.3[0-14715].0[0-14730] np: 1  1750407852.243141  1750407852.247919  (f:0 main)  (s:2 14715):  < pid: 14730 > is a BACKGROUND FORK
log.3[0-14715].0[0-14731] np: 1  1750407852.243141  1750407852.248008  (f:0 main)  (s:2 14715):  < pid: 14731 > is a BACKGROUND FORK
log.3[0-14715].0[0-14732] np: 1  1750407852.243141  1750407852.248169  (f:0 main)  (s:2 14715):  < pid: 14732 > is a BACKGROUND FORK
log.3[0-14715] np: 1  1750407852.243141  1750407852.248496  (f:0 main)  (s:1 14715):  < 'echo 4' > is a SIMPLE FORK
11
log.4[0-14715] np: 1  1750407852.249084  1750407852.249154  (f:0 main)  (s:1 14715):  < 'echo 11' > is a NORMAL COMMAND
9.1
log.3[0-14715].0[0-14735] np: 1  1750407852.243141  1750407852.249255  (f:0 main)  (s:2 14715):  < pid: 14735 > is a BACKGROUND FORK
log.3[0-14715].0[0-14729].0[0-14729] np: 1  1750407852.248880  1750407852.249350  (f:0 main)  (s:2 14715.14729):  < 'echo 9' > is a SIMPLE FORK *
9.1b
12
log.3[0-14715].0[0-14733] np: 1  1750407852.243141  1750407852.249463  (f:0 main)  (s:2 14715):  < pid: 14733 > is a BACKGROUND FORK
9
log.3[0-14715].0[0-14730].0[0-14730] np: 1  1750407852.249878  1750407852.249975  (f:0 main)  (s:2 14715.14730):  < 'echo 9.1' > is a NORMAL COMMAND
9.1c
log.3[0-14715].0[0-14732].0[0-14732] np: 1  1750407852.250216  1750407852.250285  (f:0 main)  (s:2 14715.14732):  < 'echo 9.1b' > is a NORMAL COMMAND
log.3[0-14715].0[0-14731].0[0-14731] np: 1  1750407852.248912  1750407852.249261  (f:0 main)  (s:2 14715.14731):  < 'echo 9.1a' > is a SIMPLE FORK *
9.2a
10
log.3[0-14715].0[0-14733].0[0-14733] np: 1  1750407852.250492  1750407852.250792  (f:0 main)  (s:2 14715.14733):  < 'echo 9.1c' > is a SIMPLE FORK
9.2c
log.5[0-14715].0[0-14739] np: 1  1750407852.249743  1750407852.250839  (f:0 main)  (s:2 14715):  < pid: 14739 > is a BACKGROUND FORK
13
log.3[0-14715].0[0-14735].0[0-14735] np: 1  1750407852.250046  1750407852.251378  (f:0 main)  (s:2 14715.14735):  < 'echo 10' > is a SIMPLE FORK *
log.3[0-14715].0[0-14733].1[0-14733] np: 1  1750407852.251360  1750407852.251429  (f:0 main)  (s:2 14715.14733):  < 'echo 9.2c' > is a NORMAL COMMAND
log.5[0-14715].0[0-14739].0[0-14739] np: 1  1750407852.251604  1750407852.251662  (f:0 main)  (s:2 14715.14739):  < 'echo 13' > is a NORMAL COMMAND
log.3[0-14715].0[0-14730].1[0-14730] np: 1  1750407852.250640  1750407852.251878  (f:0 main)  (s:2 14715.14730):  < 'echo 9.2' > is a SIMPLE FORK
log.5[0-14715].0[0-14740] np: 1  1750407852.249743  1750407852.251710  (f:0 main)  (s:2 14715):  < pid: 14740 > is a SUBSHELL
9.2b
14
log.3[0-14715].0[0-14731].1[0-14731] np: 1  1750407852.251144  1750407852.251227  (f:0 main)  (s:2 14715.14731):  < 'echo 9.2a' > is a NORMAL COMMAND
log.3[0-14715].0[0-14734] np: 1  1750407852.243141  1750407852.249338  (f:0 main)  (s:2 14715):  < pid: 14734 > is a BACKGROUND FORK
9.999
9.1a
log.3[0-14715].0[0-14732].1[0-14732] np: 1  1750407852.250852  1750407852.252429  (f:0 main)  (s:2 14715.14732):  < 'echo 9.2b' > is a SIMPLE FORK
log.5[0-14715].0[0-14740].0[0-14740] np: 1  1750407852.252528  1750407852.252612  (f:0 main)  (s:2 14715.14740):  < 'echo 14' > is a NORMAL COMMAND
9.2
log.3[0-14715].0[0-14734].0[0-14734].0[0-14745] np: 1  1750407852.252855  1750407852.253404  (f:0 main)  (s:3 14715.14734):  < pid: 14745 > is a SUBSHELL
log.5[0-14715] np: 1  1750407852.249743  1750407852.253456  (f:0 main)  (s:1 14715):  < 'echo 12' > is a SIMPLE FORK
9.3
log.3[0-14715].0[0-14734].0[0-14734].0[0-14745].0[0-14745] np: 1  1750407852.254047  1750407852.254327  (f:0 main)  (s:3 14715.14734.14745):  < 'echo 9.3' > is a SIMPLE FORK
9.4
log.3[0-14715].0[0-14734].0[0-14734].0[0-14745].1[0-14745] np: 1  1750407852.254844  1750407852.254895  (f:0 main)  (s:3 14715.14734.14745):  < 'echo 9.4' > is a NORMAL COMMAND
log.7.0[0-14715] np: 1  1750407852.254683  1750407852.254748  (f:2 main.ff)  (s:1 14715):  < 'ff 15' > is a FUNCTION (C)
15
log.3[0-14715].0[0-14734].0[0-14734] np: 1  1750407852.252855  1750407852.255412  (f:0 main)  (s:2 14715.14734):  < 'echo 9.999' > is a NORMAL COMMAND
9.5
log.7.1[0-14715] np: 1  1750407852.255315  1750407852.255392  (f:2 main.ff)  (s:1 14715):  < 'echo "${*}"' > is a NORMAL COMMAND
log.3[0-14715].0[0-14734].1[0-14734] np: 1  1750407852.255881  1750407852.255929  (f:0 main)  (s:2 14715.14734):  < 'echo 9.5' > is a NORMAL COMMAND
log.7[0-14715] np: 1  1750407852.254077  1750407852.258315  (f:0 main)  (s:1 14715):  < 'ff 15' > is a FUNCTION (P)
log.9.0[0-14715] np: 1  1750407852.259543  1750407852.259596  (f:2 main.gg)  (s:1 14715):  < 'gg 16' > is a FUNCTION (C)
16
log.9.1[0-14715] np: 1  1750407852.260199  1750407852.260266  (f:2 main.gg)  (s:1 14715):  < 'echo "$*"' > is a NORMAL COMMAND
log.9.3.0[0-14715] np: 1  1750407852.261444  1750407852.261493  (f:3 main.gg.ff)  (s:1 14715):  < 'ff "$@"' > is a FUNCTION (C)
16
log.9.3.1[0-14715] np: 1  1750407852.262112  1750407852.262186  (f:3 main.gg.ff)  (s:1 14715):  < 'echo "${*}"' > is a NORMAL COMMAND
log.9.3[0-14715] np: 1  1750407852.260847  1750407852.265076  (f:2 main.gg)  (s:1 14715):  < 'ff "$@"' > is a FUNCTION (P)
log.9[0-14715].0[0-14747] np: 1  1750407852.258923  1750407852.268519  (f:0 main)  (s:2 14715):  < pid: 14747 > is a BACKGROUND FORK
a
log.9[0-14715].0[0-14749] np: 1  1750407852.258923  1750407852.269042  (f:0 main)  (s:2 14715):  < pid: 14749 > is a SUBSHELL
log.9[0-14715].0[1-1].0[1-14750] np: 1  1750407852.258923  1750407852.268978  (f:0 main)  (s:3 14715.1):  < pid: 14750 > is a BACKGROUND FORK
b
A2
log.9[0-14715].0[0-14747].0[0-14747] np: 1  1750407852.269338  1750407852.269681  (f:0 main)  (s:2 14715.14747):  < 'echo a' > is a SIMPLE FORK
log.9[0-14715].0[0-14749].0[0-14751].0[0-14752] np: 1  1750407852.258923  1750407852.269375  (f:0 main)  (s:4 14715.14749.14751):  < pid: 14752 > is a SUBSHELL
log.9[0-14715].0[1-1].0[1-14750].0[1-14750] np: 1  1750407852.269955  1750407852.270030  (f:0 main)  (s:3 14715.1.14750):  < 'echo b' > is a NORMAL COMMAND
log.9[0-14715].0[0-14749].0[0-14749] np: 1  1750407852.269854  1750407852.270156  (f:0 main)  (s:2 14715.14749):  < 'echo A2' > is a SIMPLE FORK
A5
A1
log.9[0-14715].0[0-14749].1[0-14749] np: 1  1750407852.270689  1750407852.270783  (f:0 main)  (s:2 14715.14749):  < 'echo A1' > is a NORMAL COMMAND
log.9[0-14715].0[0-14749].0[0-14751].0[0-14752].0[0-14752] np: 1  1750407852.270329  1750407852.270678  (f:0 main)  (s:4 14715.14749.14751.14752):  < 'echo A5' > is a SIMPLE FORK
log.9[0-14715] np: 1  1750407852.258923  1750407852.271647  (f:0 main)  (s:1 14715):  < 'gg 16' > is a FUNCTION (P)
log.9[0-14715].0[1-1].0[1-14751].0[1-14756] np: 1  1750407852.258923  1750407852.271953  (f:0 main)  (s:4 14715.1.14751):  < pid: 14756 > is a BACKGROUND FORK
log.9[0-14715].0[1-1].0[1-14751] np: 1  1750407852.258923  1750407852.271916  (f:0 main)  (s:3 14715.1):  < pid: 14751 > is a BACKGROUND FORK
A4
A3
log.10[0-14715] np: 1  1750407852.272204  1750407852.272501  (f:0 main)  (s:1 14715):  < $'cat <<EOF\nfoo\nbar\nbaz\nEOF\n' > is a NORMAL COMMAND
log.9[0-14715].0[1-1].0[1-14751].0[1-14756].0[1-14756] np: 1  1750407852.272996  1750407852.273075  (f:0 main)  (s:4 14715.1.14751.14756):  < 'echo A4' > is a NORMAL COMMAND
log.9[0-14715].0[1-1].0[1-14751].0[1-14751] np: 1  1750407852.273004  1750407852.273074  (f:0 main)  (s:3 14715.1.14751):  < 'echo A3' > is a NORMAL COMMAND
log.11[0-14715] np: 1  1750407852.273117  1750407852.273497  (f:0 main)  (s:1 14715):  < 'grep foo' > is a NORMAL COMMAND
log.12[0-14715] np: 1  1750407852.274308  1750407852.274680  (f:0 main)  (s:1 14715):  < 'sed '\''s/o/O/g'\''' > is a NORMAL COMMAND
1
log.13[0-14715] np: 4  1750407852.275294  1750407852.313380  (f:0 main)  (s:1 14715):  < 'wc -l' > is a NORMAL COMMAND
log.14[0-14715].0[0-14761] np: 4  1750407852.314032  1750407852.314592  (f:0 main)  (s:2 14715):  < pid: 14761 > is a SUBSHELL
today is 2025-06-20
log.14[0-14715] np: 1  1750407852.314032  1750407852.316787  (f:0 main)  (s:1 14715):  < 'echo "today is $(date +%Y-%m-%d)"' > is a NORMAL COMMAND
log.15[0-14715].0[0-14762] np: 1  1750407852.317382  1750407852.318130  (f:0 main)  (s:2 14715):  < pid: 14762 > is a SUBSHELL
log.15[0-14715].0[0-14762].0[0-14763] np: 1  1750407852.317382  1750407852.318201  (f:0 main)  (s:3 14715.14762):  < pid: 14763 > is a SUBSHELL
log.15[0-14715].0[0-14762].0[0-14763].0[0-14763] np: 1  1750407852.319557  1750407852.319638  (f:0 main)  (s:3 14715.14762.14763):  < 'echo nested' > is a NORMAL COMMAND
log.15[0-14715].0[0-14762].0[0-14763].1[0-14763] np: 1  1750407852.320203  1750407852.320284  (f:0 main)  (s:3 14715.14762.14763):  < 'echo subshell' > is a NORMAL COMMAND
log.15[0-14715].0[0-14762].0[0-14762] np: 2  1750407852.318929  1750407852.321322  (f:0 main)  (s:2 14715.14762):  < 'grep sub' > is a NORMAL COMMAND
log.15[0-14715] np: 1  1750407852.317382  1750407852.322510  (f:0 main)  (s:1 14715):  < 'x=$( ( echo nested; echo subshell ) | grep sub)' > is a NORMAL COMMAND
log.16[0-14715].0[0-14765] np: 1  1750407852.323298  1750407852.323795  (f:0 main)  (s:2 14715):  < pid: 14765 > is a SUBSHELL
log.16[0-14715].0[0-14766] np: 1  1750407852.323298  1750407852.324001  (f:0 main)  (s:2 14715):  < pid: 14766 > is a SUBSHELL
1,22c1
< bin
< boot
< dev
< etc
< home
< lib
< lib32
< lib64
< lib.usr-is-merged
< media
< mnt
< opt
< proc
< root
< run
< sbin
< script
< srv
< sys
< tmp
< usr
< var
---
> hsperfdata_runner56
log.16[0-14715] np: 1  1750407852.323298  1750407852.326175  (f:0 main)  (s:1 14715):  < 'diff <(ls /) <(ls /tmp)' > is a SIMPLE FORK
log.17[0-14715].0[0-14768] np: 1  1750407852.326808  1750407852.327238  (f:0 main)  (s:2 14715):  < pid: 14768 > is a SUBSHELL
log.17[0-14715].0[0-14770] np: 1  1750407852.326808  1750407852.328942  (f:0 main)  (s:2 14715):  < pid: 14770 > is a BACKGROUND FORK
log.17[0-14715] np: 1  1750407852.326808  1750407852.328890  (f:0 main)  (s:1 14715):  < 'grep pattern <(sed '\''s/^/>>/'\'' > /dev/null)' > is a SIMPLE FORK
log.17[0-14715].0[0-14770].0[0-14770] np: 1  1750407852.329537  1750407852.329594  (f:0 main)  (s:2 14715.14770):  < 'for i in {1..3}' > is a NORMAL COMMAND
log.17[0-14715].0[0-14770].1[0-14770] np: 1  1750407852.329989  1750407852.330032  (f:0 main)  (s:2 14715.14770):  < 'echo "$i"' > is a NORMAL COMMAND
log.18[0-14715] np: 1  1750407852.329599  1750407852.330078  (f:0 main)  (s:1 14715):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 1
log.19[0-14715] np: 1  1750407852.330761  1750407852.330834  (f:0 main)  (s:1 14715):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
log.17[0-14715].0[0-14770].2[0-14770] np: 1  1750407852.330343  1750407852.341699  (f:0 main)  (s:2 14715.14770):  < 'sleep .01' > is a NORMAL COMMAND
log.17[0-14715].0[0-14770].3[0-14770] np: 1  1750407852.342375  1750407852.342434  (f:0 main)  (s:2 14715.14770):  < 'for i in {1..3}' > is a NORMAL COMMAND
log.17[0-14715].0[0-14770].4[0-14770] np: 1  1750407852.343056  1750407852.343123  (f:0 main)  (s:2 14715.14770):  < 'echo "$i"' > is a NORMAL COMMAND
log.20[0-14715] np: 1  1750407852.331461  1750407852.343211  (f:0 main)  (s:1 14715):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 2
log.21[0-14715] np: 1  1750407852.343970  1750407852.344057  (f:0 main)  (s:1 14715):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
log.17[0-14715].0[0-14770].5[0-14770] np: 1  1750407852.343714  1750407852.355099  (f:0 main)  (s:2 14715.14770):  < 'sleep .01' > is a NORMAL COMMAND
log.17[0-14715].0[0-14770].6[0-14770] np: 1  1750407852.355583  1750407852.355651  (f:0 main)  (s:2 14715.14770):  < 'for i in {1..3}' > is a NORMAL COMMAND
log.17[0-14715].0[0-14770].7[0-14770] np: 1  1750407852.356100  1750407852.356143  (f:0 main)  (s:2 14715.14770):  < 'echo "$i"' > is a NORMAL COMMAND
log.22[0-14715] np: 1  1750407852.344709  1750407852.356250  (f:0 main)  (s:1 14715):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 3
log.23[0-14715] np: 1  1750407852.356961  1750407852.357043  (f:0 main)  (s:1 14715):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
log.17[0-14715].0[0-14770].8[0-14770] np: 1  1750407852.356594  1750407852.368164  (f:0 main)  (s:2 14715.14770):  < 'sleep .01' > is a NORMAL COMMAND
log.24[0-14715] np: 1  1750407852.357698  1750407852.369065  (f:0 main)  (s:1 14715):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
log.25[0-14715] np: 1  1750407852.369764  1750407852.369831  (f:0 main)  (s:1 14715):  < 'let "x = 5 + 6"' > is a NORMAL COMMAND
log.26[0-14715] np: 1  1750407852.370486  1750407852.370560  (f:0 main)  (s:1 14715):  < 'arr=(one two three)' > is a NORMAL COMMAND
one two three
log.27[0-14715] np: 1  1750407852.371222  1750407852.371309  (f:0 main)  (s:1 14715):  < 'echo ${arr[@]}' > is a NORMAL COMMAND
log.28[0-14715] np: 1  1750407852.371967  1750407852.372024  (f:0 main)  (s:1 14715):  < '((i=0))' > is a NORMAL COMMAND
log.29[0-14715] np: 1  1750407852.372659  1750407852.372717  (f:0 main)  (s:1 14715):  < '((i<3))' > is a NORMAL COMMAND
0
log.30[0-14715] np: 1  1750407852.373382  1750407852.373453  (f:0 main)  (s:1 14715):  < 'echo "$i"' > is a NORMAL COMMAND
log.31[0-14715] np: 1  1750407852.374120  1750407852.374177  (f:0 main)  (s:1 14715):  < '((i++))' > is a NORMAL COMMAND
log.32[0-14715] np: 1  1750407852.374836  1750407852.374898  (f:0 main)  (s:1 14715):  < '((i<3))' > is a NORMAL COMMAND
1
log.33[0-14715] np: 1  1750407852.375525  1750407852.375609  (f:0 main)  (s:1 14715):  < 'echo "$i"' > is a NORMAL COMMAND
log.34[0-14715] np: 1  1750407852.376251  1750407852.376310  (f:0 main)  (s:1 14715):  < '((i++))' > is a NORMAL COMMAND
log.35[0-14715] np: 1  1750407852.376982  1750407852.377043  (f:0 main)  (s:1 14715):  < '((i<3))' > is a NORMAL COMMAND
2
log.36[0-14715] np: 1  1750407852.377708  1750407852.377809  (f:0 main)  (s:1 14715):  < 'echo "$i"' > is a NORMAL COMMAND
log.37[0-14715] np: 1  1750407852.378516  1750407852.378586  (f:0 main)  (s:1 14715):  < '((i++))' > is a NORMAL COMMAND
log.38[0-14715] np: 1  1750407852.379298  1750407852.379378  (f:0 main)  (s:1 14715):  < '((i<3))' > is a NORMAL COMMAND
log.39[0-14715] np: 1  1750407852.380086  1750407852.380146  (f:0 main)  (s:1 14715):  < 'cmd="echo inside-eval"' > is a NORMAL COMMAND
log.40[0-14715] np: 1  1750407852.380799  1750407852.380870  (f:0 main)  (s:1 14715):  < 'eval "$cmd"' > is a NORMAL COMMAND
inside-eval
log.41[0-14715] np: 1  1750407852.381483  1750407852.381566  (f:0 main)  (s:1 14715):  < 'echo inside-eval' > is a NORMAL COMMAND
log.42[0-14715] np: 1  1750407852.382184  1750407852.382252  (f:0 main)  (s:1 14715):  < 'eval "eval \"$cmd\""' > is a NORMAL COMMAND
log.43[0-14715] np: 1  1750407852.382898  1750407852.382967  (f:0 main)  (s:1 14715):  < 'eval "echo inside-eval"' > is a NORMAL COMMAND
inside-eval
log.44[0-14715] np: 1  1750407852.394360  1750407852.394438  (f:0 main)  (s:1 14715):  < 'kill -USR1 $BASHPID' > is a NORMAL COMMAND
got USR1
log.45[0-14715] np: 1  1750407852.395123  1750407852.395194  (f:0 main)  (s:1 14715):  < 'kill -USR1 $BASHPID' > is a NORMAL COMMAND
log.46[0-14715] np: 1  1750407852.395839  1750407852.407331  (f:0 main)  (s:1 14715):  < 'kill -USR1 $BASHPID' > is a NORMAL COMMAND
after-signal
log.47[0-14715] np: 1  1750407852.408069  1750407852.408154  (f:0 main)  (s:1 14715):  < 'echo after-signal' > is a NORMAL COMMAND
log.48[0-14715].0[0-14775] np: 1  1750407852.408837  1750407852.409365  (f:0 main)  (s:2 14715):  < pid: 14775 > is a SUBSHELL
log.48[0-14715] np: 1  1750407852.408837  1750407852.409299  (f:0 main)  (s:1 14715):  < 'for i in {1..3}' > is a SIMPLE FORK
log.49[0-14715] np: 1  1750407852.410063  1750407852.411448  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.50[0-14715].0[0-14776] np: 1  1750407852.412160  1750407852.412715  (f:0 main)  (s:2 14715):  < pid: 14776 > is a SUBSHELL
odd 1
log.50[0-14715].0[0-14776].0[0-14776] np: 1  1750407852.413240  1750407852.413290  (f:0 main)  (s:2 14715.14776):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.50[0-14715] np: 1  1750407852.412160  1750407852.414071  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.51[0-14715] np: 1  1750407852.414757  1750407852.414836  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.52[0-14715] np: 1  1750407852.415469  1750407852.415551  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 2
log.53[0-14715] np: 1  1750407852.416203  1750407852.416277  (f:0 main)  (s:1 14715):  < 'echo even "$x"' > is a NORMAL COMMAND
log.54[0-14715] np: 1  1750407852.416957  1750407852.417026  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.55[0-14715].0[0-14777] np: 1  1750407852.417687  1750407852.418182  (f:0 main)  (s:2 14715):  < pid: 14777 > is a SUBSHELL
odd 3
log.55[0-14715].0[0-14777].0[0-14777] np: 1  1750407852.418664  1750407852.418712  (f:0 main)  (s:2 14715.14777):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.55[0-14715] np: 1  1750407852.417687  1750407852.419371  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.56[0-14715] np: 1  1750407852.419873  1750407852.419932  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.57[0-14715] np: 1  1750407852.420431  1750407852.420468  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 4
log.58[0-14715] np: 1  1750407852.420882  1750407852.420922  (f:0 main)  (s:1 14715):  < 'echo even "$x"' > is a NORMAL COMMAND
log.59[0-14715] np: 1  1750407852.421433  1750407852.421473  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.60[0-14715].0[0-14778] np: 1  1750407852.421843  1750407852.422262  (f:0 main)  (s:2 14715):  < pid: 14778 > is a SUBSHELL
odd 5
log.60[0-14715].0[0-14778].0[0-14778] np: 1  1750407852.422889  1750407852.422941  (f:0 main)  (s:2 14715.14778):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.60[0-14715] np: 1  1750407852.421843  1750407852.423596  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.61[0-14715] np: 1  1750407852.424185  1750407852.424263  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.62[0-14715] np: 1  1750407852.424964  1750407852.425297  (f:0 main)  (s:1 14715):  < 'for i in {1..3}' > is a SIMPLE FORK
log.62[0-14715].0[0-14779] np: 1  1750407852.424964  1750407852.425355  (f:0 main)  (s:2 14715):  < pid: 14779 > is a SUBSHELL
log.63[0-14715] np: 1  1750407852.425939  1750407852.426903  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.64[0-14715].0[0-14780] np: 1  1750407852.427477  1750407852.427985  (f:0 main)  (s:2 14715):  < pid: 14780 > is a SUBSHELL
odd 1
log.64[0-14715].0[0-14780].0[0-14780] np: 1  1750407852.428565  1750407852.428623  (f:0 main)  (s:2 14715.14780):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.64[0-14715] np: 1  1750407852.427477  1750407852.429279  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.65[0-14715] np: 1  1750407852.429975  1750407852.430048  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.66[0-14715] np: 1  1750407852.430689  1750407852.430774  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 2
log.67[0-14715] np: 1  1750407852.431421  1750407852.431498  (f:0 main)  (s:1 14715):  < 'echo even "$x"' > is a NORMAL COMMAND
log.68[0-14715] np: 1  1750407852.432170  1750407852.432237  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.69[0-14715].0[0-14781] np: 1  1750407852.432909  1750407852.433327  (f:0 main)  (s:2 14715):  < pid: 14781 > is a SUBSHELL
odd 3
log.69[0-14715].0[0-14781].0[0-14781] np: 1  1750407852.433843  1750407852.433897  (f:0 main)  (s:2 14715.14781):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.69[0-14715] np: 1  1750407852.432909  1750407852.434593  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.70[0-14715] np: 1  1750407852.435292  1750407852.435364  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.71[0-14715] np: 1  1750407852.436036  1750407852.436614  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 4
log.72[0-14715] np: 1  1750407852.437313  1750407852.437385  (f:0 main)  (s:1 14715):  < 'echo even "$x"' > is a NORMAL COMMAND
log.73[0-14715] np: 1  1750407852.438076  1750407852.438145  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.74[0-14715].0[0-14782] np: 1  1750407852.438829  1750407852.439291  (f:0 main)  (s:2 14715):  < pid: 14782 > is a SUBSHELL
odd 5
log.74[0-14715].0[0-14782].0[0-14782] np: 1  1750407852.440050  1750407852.440116  (f:0 main)  (s:2 14715.14782):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.74[0-14715] np: 1  1750407852.438829  1750407852.440932  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.75[0-14715] np: 1  1750407852.441606  1750407852.441689  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.76[0-14715].0[0-14783] np: 1  1750407852.442342  1750407852.442833  (f:0 main)  (s:2 14715):  < pid: 14783 > is a SUBSHELL
log.76[0-14715] np: 1  1750407852.442342  1750407852.442768  (f:0 main)  (s:1 14715):  < 'for i in {1..3}' > is a SIMPLE FORK
log.77[0-14715] np: 1  1750407852.443501  1750407852.444270  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.78[0-14715].0[0-14784] np: 1  1750407852.444988  1750407852.445442  (f:0 main)  (s:2 14715):  < pid: 14784 > is a SUBSHELL
odd 1
log.78[0-14715].0[0-14784].0[0-14784] np: 1  1750407852.446202  1750407852.446253  (f:0 main)  (s:2 14715.14784):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.78[0-14715] np: 1  1750407852.444988  1750407852.446862  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.79[0-14715] np: 1  1750407852.447482  1750407852.447538  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.80[0-14715] np: 1  1750407852.448075  1750407852.448124  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 2
log.81[0-14715] np: 1  1750407852.448705  1750407852.448784  (f:0 main)  (s:1 14715):  < 'echo even "$x"' > is a NORMAL COMMAND
log.82[0-14715] np: 1  1750407852.449365  1750407852.449427  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.83[0-14715].0[0-14785] np: 1  1750407852.449999  1750407852.450416  (f:0 main)  (s:2 14715):  < pid: 14785 > is a SUBSHELL
odd 3
log.83[0-14715].0[0-14785].0[0-14785] np: 1  1750407852.450939  1750407852.450990  (f:0 main)  (s:2 14715.14785):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.83[0-14715] np: 1  1750407852.449999  1750407852.451579  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.84[0-14715] np: 1  1750407852.452101  1750407852.452167  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.85[0-14715] np: 1  1750407852.452712  1750407852.452774  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 4
log.86[0-14715] np: 1  1750407852.453344  1750407852.453398  (f:0 main)  (s:1 14715):  < 'echo even "$x"' > is a NORMAL COMMAND
log.87[0-14715] np: 1  1750407852.453917  1750407852.453959  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND
log.88[0-14715].0[0-14786] np: 1  1750407852.454297  1750407852.454762  (f:0 main)  (s:2 14715):  < pid: 14786 > is a SUBSHELL
odd 5
log.88[0-14715].0[0-14786].0[0-14786] np: 1  1750407852.455568  1750407852.455639  (f:0 main)  (s:2 14715.14786):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.88[0-14715] np: 1  1750407852.454297  1750407852.456735  (f:0 main)  (s:1 14715):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.89[0-14715].0[0-14787] np: 1    1750407852.463198  (f:0 main)  (s:2 14715):  < pid: 14787 > is a SUBSHELL
log.89[0-14715].0[0-14787].0[0-14787] np: 1  1750407852.463687  1750407852.463757  (f:0 main)  (s:2 14715.14787):  < 'exit' > is a NORMAL COMMAND
bye
log.89[0-14715].0[0-14788] np: 1    1750407852.471511  (f:0 main)  (s:2 14715):  < pid: 14788 > is a SUBSHELL
log.89[0-14715].0[0-14788].1.0[0-14788] np: 1  1750407852.472669  1750407852.472714  (f:2 main.gg)  (s:2 14715.14788):  < 'gg 1' > is a FUNCTION (C)
1
log.89[0-14715].0[0-14788].1.1[0-14788] np: 1  1750407852.473200  1750407852.473260  (f:2 main.gg)  (s:2 14715.14788):  < 'echo "$*"' > is a NORMAL COMMAND
log.89[0-14715].0[0-14788].1.3.0[0-14788] np: 1  1750407852.474305  1750407852.474353  (f:3 main.gg.ff)  (s:2 14715.14788):  < 'ff "$@"' > is a FUNCTION (C)
1
log.89[0-14715].0[0-14788].1.3.1[0-14788] np: 1  1750407852.474760  1750407852.474814  (f:3 main.gg.ff)  (s:2 14715.14788):  < 'echo "${*}"' > is a NORMAL COMMAND
bye
log.89[0-14715].0[0-14788].1.3.2[0-14788] np: 1  1750407852.475116  1750407852.475165  (f:3 main.gg.ff)  (s:2 14715.14788):  < 'echo "${*}"' > is a NORMAL COMMAND
log.89[0-14715].0[0-14788].1.3[0-14788] np: 1  1750407852.473770  1750407852.477579  (f:2 main.gg)  (s:2 14715.14788):  < 'ff "$@"' > is a FUNCTION (P)
bye
log.89[0-14715].0[0-14788].1.4[0-14788] np: 1  1750407852.478097  1750407852.478158  (f:2 main.gg)  (s:2 14715.14788):  < 'echo "${*}"' > is a NORMAL COMMAND
log.89[0-14715].0[0-14788].1[0-14788] np: 1  1750407852.472213  1750407852.480602  (f:0 main)  (s:2 14715.14788):  < 'gg 1' > is a FUNCTION (P)
log.89[0-14715].0[0-14788].2[0-14788] np: 1  1750407852.481110  1750407852.481171  (f:0 main)  (s:2 14715.14788):  < 'exit' > is a NORMAL COMMAND
return
log.89[0-14715].0[0-14789] np: 1    1750407852.493673  (f:0 main)  (s:2 14715):  < pid: 14789 > is a SUBSHELL
log.89[0-14715].0[0-14789].1.0[0-14789] np: 1  1750407852.494809  1750407852.494853  (f:2 main.gg)  (s:2 14715.14789):  < 'gg 1' > is a FUNCTION (C)
1
log.89[0-14715].0[0-14789].1.1[0-14789] np: 1  1750407852.495282  1750407852.495341  (f:2 main.gg)  (s:2 14715.14789):  < 'echo "$*"' > is a NORMAL COMMAND
log.89[0-14715].0[0-14789].1.3.0[0-14789] np: 1  1750407852.496217  1750407852.496260  (f:3 main.gg.ff)  (s:2 14715.14789):  < 'ff "$@"' > is a FUNCTION (C)
1
log.89[0-14715].0[0-14789].1.3.1[0-14789] np: 1  1750407852.496597  1750407852.496639  (f:3 main.gg.ff)  (s:2 14715.14789):  < 'echo "${*}"' > is a NORMAL COMMAND
return
log.89[0-14715].0[0-14789].1.3.2[0-14789] np: 1  1750407852.496975  1750407852.497017  (f:3 main.gg.ff)  (s:2 14715.14789):  < 'echo "${*}"' > is a NORMAL COMMAND
log.89[0-14715].0[0-14789].1.3[0-14789] np: 1  1750407852.495744  1750407852.498898  (f:2 main.gg)  (s:2 14715.14789):  < 'ff "$@"' > is a FUNCTION (P)
return
log.89[0-14715].0[0-14789].1.4[0-14789] np: 1  1750407852.499199  1750407852.499248  (f:2 main.gg)  (s:2 14715.14789):  < 'echo "${*}"' > is a NORMAL COMMAND
log.89[0-14715].0[0-14789].1[0-14789] np: 1  1750407852.494290  1750407852.500946  (f:0 main)  (s:2 14715.14789):  < 'gg 1' > is a FUNCTION (P)
log.89[0-14715].0[0-14789].2[0-14789] np: 1  1750407852.501421  1750407852.501477  (f:0 main)  (s:2 14715.14789):  < 'exit' > is a NORMAL COMMAND
log.89[0-14715].0[0-14790] np: 1    1750407852.512677  (f:0 main)  (s:2 14715):  < pid: 14790 > is a SUBSHELL
log.89[0-14715].0[0-14790].0[0-14790] np: 1  1750407852.513135  1750407852.513179  (f:0 main)  (s:2 14715.14790):  < 'exit' > is a NORMAL COMMAND
log.89[0-14715].0[0-14791] np: 1    1750407852.519253  (f:0 main)  (s:2 14715):  < pid: 14791 > is a SUBSHELL
log.89[0-14715].0[0-14791].0[0-14791] np: 1  1750407852.519907  1750407852.519969  (f:0 main)  (s:2 14715.14791):  < 'exit' > is a NORMAL COMMAND
log.89[0-14715].0[0-14792].0[0-14793].0[0-14794].0[0-14795] np: 1  1750407852.457350  1750407852.521595  (f:0 main)  (s:5 14715.14792.14793.14794):  < pid: 14795 > is a SUBSHELL
14795
log.89[0-14715].0[0-14792].0[0-14793].0[0-14794].0[0-14795].0[0-14795] np: 1  1750407852.522562  1750407852.522621  (f:0 main)  (s:5 14715.14792.14793.14794.14795):  < 'echo $BASHPID' > is a NORMAL COMMAND
log.89[0-14715].0[0-14792].0[0-14793].0[0-14794] np: 1  1750407852.457350  1750407852.523312  (f:0 main)  (s:4 14715.14792.14793):  < pid: 14794 > is a SUBSHELL
14794
log.89[0-14715].0[0-14792].0[0-14793].0[0-14794].0[0-14794] np: 1  1750407852.524007  1750407852.524057  (f:0 main)  (s:4 14715.14792.14793.14794):  < 'echo $BASHPID' > is a NORMAL COMMAND
log.89[0-14715].0[0-14792].0[0-14793] np: 1  1750407852.457350  1750407852.524884  (f:0 main)  (s:3 14715.14792):  < pid: 14793 > is a SUBSHELL
14793
log.89[0-14715].0[0-14792].0[0-14793].0[0-14793] np: 1  1750407852.525658  1750407852.525757  (f:0 main)  (s:3 14715.14792.14793):  < 'echo $BASHPID' > is a NORMAL COMMAND
log.89[0-14715].0[0-14792] np: 1  1750407852.457350  1750407852.526718  (f:0 main)  (s:2 14715):  < pid: 14792 > is a SUBSHELL
14792
log.89[0-14715].0[0-14792].0[0-14792] np: 1  1750407852.527374  1750407852.527424  (f:0 main)  (s:2 14715.14792):  < 'echo $BASHPID' > is a NORMAL COMMAND
log.89[0-14715] np: 1  1750407852.457350  1750407852.528232  (f:0 main)  (s:1 14715):  < 'read x' > is a NORMAL COMMAND

```

#####################################################################



```
(
set -T
set -m

: &

read -r _ _ _ _ timep_PARENT_PGID _ _ timep_PARENT_TPID _ </proc/${BASHPID}/stat
timep_CHILD_PGID="$timep_PARENT_PGID"
timep_CHILD_TPID="$timep_PARENT_TPID"

timep_BASHPID_PREV="$BASHPID"
timep_BG_PID_PREV="$!"
timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
timep_SUBSHELL_BASHPID_CUR=''
timep_NEXEC_0=''
timep_NEXEC_A=('0')
timep_NPIDWRAP='0'
timep_BASHPID_STR="${BASHPID}"
timep_FUNCNAME_STR="main"

timep_SIMPLEFORK_NEXT_FLAG=false
timep_SIMPLEFORK_CUR_FLAG=false
timep_SKIP_DEBUG_FLAG=false
timep_NO_PRINT_FLAG=false
timep_IS_FUNC_FLAG_1=false

timep_BASH_COMMAND_PREV=()
timep_NPIPE=()
timep_STARTTIME=()

timep_FNEST=("${#FUNCNAME[@]}")
timep_FNEST_CUR="${#FUNCNAME[@]}"

timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]=''
timep_NPIPE[${timep_FNEST_CUR}]='0'
timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"

ff() { echo "${*}"; }

builtin trap - EXIT RETURN DEBUG

export -p timep_RETURN_TRAP_STR &>/dev/null && export -n timep_RETURN_TRAP_STR

declare -gxr timep_RETURN_TRAP_STR='timep_SKIP_DEBUG_FLAG=true
unset "timep_FNEST[-1]" "timep_NEXEC_A[-1]" "timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]" "timep_NPIPE[${timep_FNEST_CUR}]" "timep_STARTTIME[${timep_FNEST_CUR}]"
timep_NEXEC_0="${timep_NEXEC_0%.*}"
timep_FUNCNAME_STR="${timep_FUNCNAME_STR%.*}"
timep_FNEST_CUR="${timep_FNEST[-1]}"
timep_SKIP_DEBUG_FLAG=false'

export -p timep_DEBUG_TRAP_STR &>/dev/null && export -n timep_DEBUG_TRAP_STR
declare -agxr timep_DEBUG_TRAP_STR=('timep_NPIPE0="${#PIPESTATUS[@]}"
timep_ENDTIME0="${EPOCHREALTIME}"
' '
[[ "$-" == *m* ]] || { 
  printf '"'"'\nWARNING: timep requires job control to be enabled.\n         Running "set +m" is not allowed!\n         Job control will automatically be re-enabled.\n\n'"'"' >&2
  set -m
}
[[ "${BASH_COMMAND}" == trap\ * ]] && {
  timep_SKIP_DEBUG_FLAG=true
  (( timep_FNEST_CUR == ${#FUNCNAME[@]} )) && {
    timep_FNEST_CUR="${#FUNCNAME[@]}"
    timep_FNEST+=("${#FUNCNAME[@]}")
    timep_BASH_COMMAND_PREV+=("${BASH_COMMAND}")
    timep_FUNCNAME_STR+=".trap"
    timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
    timep_NEXEC_A+=("0")
  }
}
${timep_SKIP_DEBUG_FLAG} || {
timep_NPIPE[${timep_FNEST_CUR}]=${timep_NPIPE0}
timep_ENDTIME=${timep_ENDTIME0}
timep_IS_BG_FLAG=false
timep_IS_SUBSHELL_FLAG=false
timep_IS_FUNC_FLAG=false
timep_CMD_TYPE='"''"'
if ${timep_SIMPLEFORK_NEXT_FLAG}; then
  timep_SIMPLEFORK_NEXT_FLAG=false
  timep_SIMPLEFORK_CUR_FLAG=true
else
  timep_SIMPLEFORK_CUR_FLAG=false
fi
if (( timep_BASH_SUBSHELL_PREV == BASH_SUBSHELL )); then
  if (( timep_BG_PID_PREV == $! )); then
    (( timep_FNEST_CUR >= ${#FUNCNAME[@]} )) || {
      timep_NO_PRINT_FLAG=true
      timep_IS_FUNC_FLAG=true
      timep_FNEST+=("${#FUNCNAME[@]}")
    }
  else
    timep_IS_BG_FLAG=true
  fi
else
  timep_IS_SUBSHELL_FLAG=true
  (( BASHPID < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
  timep_SUBSHELL_BASHPID_CUR="$BASHPID"
  builtin trap '"'"':'"'"' EXIT
  read -r _ _ _ _ timep_CHILD_PGID _ _ timep_CHILD_TPID _ </proc/${BASHPID}/stat
  (( timep_CHILD_PGID == timep_PARENT_TPID )) || (( timep_CHILD_PGID == timep_CHILD_TPID )) || {  (( timep_CHILD_PGID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )); } || timep_IS_BG_FLAG=true
fi
if ${timep_IS_SUBSHELL_FLAG} && ${timep_IS_BG_FLAG}; then
  (( timep_CHILD_PGID == BASHPID )) && (( timep_CHILD_TPID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )) && timep_SIMPLEFORK_NEXT_FLAG=true
  timep_CMD_TYPE="BACKGROUND FORK"
elif ${timep_IS_SUBSHELL_FLAG}; then
  timep_CMD_TYPE="SUBSHELL"
elif [[ "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]}" == " (F) "* ]]; then
  timep_CMD_TYPE="FUNCTION (P)"
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]# (F) }"
elif ${timep_IS_BG_FLAG}; then
  timep_CMD_TYPE="SIMPLE FORK"
elif ${timep_IS_FUNC_FLAG_1}; then
  timep_CMD_TYPE="FUNCTION (C)"
  timep_IS_FUNC_FLAG_1=false
else
  timep_CMD_TYPE="NORMAL COMMAND"
fi
if ${timep_IS_SUBSHELL_FLAG}; then
  timep_BASHPID_PREV="$BASHPID"
  (( timep_BASH_SUBSHELL_DIFF = BASH_SUBSHELL - timep_BASH_SUBSHELL_PREV + 1  ))
  timep_KK=0
        timep_BASHPID_ADD=()
        while (( timep_BASH_SUBSHELL_DIFF > 0 )); do
            (( timep_BASH_SUBSHELL_DIFF-- ))
            case "${timep_KK}" in
                0) timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}]="${BASHPID}" ;;
                1) timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}]="${timep_BASHPID_PREV}" ;;
                *) (( timep_BASH_SUBSHELL_DIFF_0 = timep_BASH_SUBSHELL_DIFF + 1 )); IFS=" " read -r _ _ _ timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}] _ </proc/${timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF_0}]}/stat ;;
            esac
            (( timep_KK++ ))
            unset "timep_BASH_SUBSHELL_DIFF_0"
        done
        unset timep_BASH_SUBSHELL_DIFF
        timep_KK=0
        while (( timep_KK < ( ${#timep_BASHPID_ADD[@]} - 2 ) )); do
            timep_BASHPID_STR+=".${timep_BASHPID_ADD[${timep_KK}]}"
            (( timep_BASHPID_ADD[${timep_KK}] < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
            timep_NEXEC_0+=".${timep_NEXEC_A[-1]}[${timep_NPIDWRAP}-${timep_BASHPID_ADD[${timep_KK}]}]"
            timep_NEXEC_A+=(0)
            timep_BASHPID_PREV="${timep_BASHPID_ADD[${timep_KK}]}"
            (( timep_KK++ ))
        done
        timep_BASHPID_PREV="${BASHPID}"
        unset "timep_KK" "timep_BASHPID_ADD"
  ${timep_NO_PRINT_FLAG} || printf '"'"'log%s.%s[%s-%s] np: %s  %s  %s  (f:%s %s)  (s:%s %s):  < pid: %s > is a %s\n'"'"' "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_NPIDWRAP}" "${BASHPID}" "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_STARTTIME[${timep_FNEST_CUR}]}" "${timep_ENDTIME}" "${timep_FNEST_CUR}" "${timep_FUNCNAME_STR}" "${BASH_SUBSHELL}" "${timep_BASHPID_STR}" "${BASHPID}" "${timep_CMD_TYPE}" >&${timep_FD}
 timep_BASHPID_STR+=".${timep_BASHPID_PREV}"
            (( BASHPID < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
            timep_NEXEC_0+=".${timep_NEXEC_A[-1]}[${timep_NPIDWRAP}-${timep_BASHPID_PREV}]"
            timep_NEXEC_A+=(0)
            timep_BASHPID_PREV="${BASHPID}"
  timep_PARENT_PGID="$timep_CHILD_PGID"
  timep_PARENT_TPID="$timep_CHILD_TPID"
  timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
elif [[ ${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]} ]]; then
  ${timep_SIMPLEFORK_CUR_FLAG} && (( BASHPID < $! )) && timep_CMD_TYPE="SIMPLE FORK *"
  ${timep_NO_PRINT_FLAG} || printf '"'"'log%s.%s[%s-%s] np: %s  %s  %s  (f:%s %s)  (s:%s %s):  < %s > is a %s\n'"'"' "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_NPIDWRAP}" "${BASHPID}" "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_STARTTIME[${timep_FNEST_CUR}]}" "${timep_ENDTIME}" "${timep_FNEST_CUR}" "${timep_FUNCNAME_STR}" "${BASH_SUBSHELL}" "${timep_BASHPID_STR}" "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]@Q}" "${timep_CMD_TYPE}" >&${timep_FD}
  (( timep_NEXEC_A[-1]++ ))
fi
if ${timep_IS_FUNC_FLAG}; then
  timep_FUNCNAME_STR+=".${FUNCNAME[0]}"
  timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
  timep_NEXEC_A+=(0)
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]=" (F) ${BASH_COMMAND}"
  timep_NPIPE[${#FUNCNAME[@]}]="${timep_NPIPE[${timep_FNEST_CUR}]}"
  timep_FNEST_CUR="${#FUNCNAME[@]}"
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${BASH_COMMAND}"
  timep_NO_PRINT_FLAG=false
  timep_IS_FUNC_FLAG_1=true
else
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="$BASH_COMMAND"
fi
timep_BG_PID_PREV="$!"
timep_BASHPID_PREV="$BASHPID"
timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"
}')

export timep_DEBUG_TRAP_STR

export -p -f trap &>/dev/null && export -n -f trap

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap "${trapStr}"':' EXIT ;;
            RETURN)  builtin trap "${trapStr}${timep_RETURN_TRAP_STR}" RETURN ;;
            DEBUG)   builtin trap "${timep_DEBUG_TRAP_STR[0]}${trapStr}${timep_DEBUG_TRAP_STR[1]}" DEBUG ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
}

export -f trap

builtin trap ':' EXIT
builtin trap "${timep_RETURN_TRAP_STR}" RETURN
builtin trap "${timep_DEBUG_TRAP_STR[0]}"$'\n'"${timep_DEBUG_TRAP_STR[1]}" DEBUG


gg() { echo "$*"; ff "$@"; }

{ echo ; } &
{ ( echo A & ); echo B; } &

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &

( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

trap 'echo got USR1; sleep .01' USR1
kill -USR1 $BASHPID
echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done

(
    trap 'echo bye' EXIT
    exit
)

(
    trap 'echo bye' RETURN EXIT
    gg 1
    exit
)

(
    trap 'echo exit' EXIT
    trap 'echo return' RETURN
    gg 1
    exit
)


(
    trap '' RETURN EXIT
    exit
)


(
    trap - EXIT
    exit
)

( ( ( ( echo $BASHPID; ); echo $BASHPID; ); echo $BASHPID; ); echo $BASHPID; ); 

builtin trap - DEBUG EXIT RETURN

) {timep_FD}>&2
```

gives

```
0
log.0[0-16947] np: 1  1750403193.424808  1750403193.426488  (f:0 main)  (s:2 16945):  < pid: 16947 > is a BACKGROUND FORK

log.0[0-16945] np: 1  1750403193.427077  1750403193.427159  (f:0 main)  (s:1 16945):  < 'echo 0' > is a NORMAL COMMAND
1
log.0[0-16947].0[0-16947] np: 1  1750403193.427453  1750403193.427517  (f:0 main)  (s:2 16945.16947):  < 'echo' > is a NORMAL COMMAND
log.0[1-16948].0[1-16949] np: 1  1750403193.424808  1750403193.427265  (f:0 main)  (s:3 16945.16948):  < pid: 16949 > is a BACKGROUND FORK
A
log.1[0-16950] np: 1  1750403193.427739  1750403193.428538  (f:0 main)  (s:2 16945):  < pid: 16950 > is a BACKGROUND FORK
2
log.0[1-16948].0[1-16949].0[1-16949] np: 1  1750403193.428465  1750403193.428984  (f:0 main)  (s:3 16945.16948.16949):  < 'echo A' > is a SIMPLE FORK
log.1[0-16950].0[0-16950] np: 1  1750403193.429287  1750403193.429368  (f:0 main)  (s:2 16945.16950):  < 'echo 2' > is a NORMAL COMMAND
log.1[0-16945] np: 1  1750403193.427739  1750403193.430373  (f:0 main)  (s:1 16945):  < 'echo 1' > is a NORMAL COMMAND
log.0[0-16948] np: 1  1750403193.424808  1750403193.430158  (f:0 main)  (s:2 16945):  < pid: 16948 > is a BACKGROUND FORK
B
3
log.0[0-16948].0[0-16948] np: 1  1750403193.431082  1750403193.431156  (f:0 main)  (s:2 16945.16948):  < 'echo B' > is a NORMAL COMMAND
log.2[0-16945] np: 1  1750403193.430948  1750403193.431441  (f:0 main)  (s:1 16945):  < 'echo 3' > is a SIMPLE FORK
4
log.3[0-16954] np: 1  1750403193.432022  1750403193.432812  (f:0 main)  (s:2 16945):  < pid: 16954 > is a BACKGROUND FORK
5
log.3[0-16955] np: 1  1750403193.432022  1750403193.432977  (f:0 main)  (s:2 16945):  < pid: 16955 > is a SUBSHELL
6
log.3[0-16954].0[0-16954] np: 1  1750403193.433492  1750403193.433559  (f:0 main)  (s:2 16945.16954):  < 'echo 5' > is a NORMAL COMMAND
log.3[0-16955].0[0-16955] np: 1  1750403193.433578  1750403193.433952  (f:0 main)  (s:2 16945.16955):  < 'echo 6' > is a SIMPLE FORK
log.3[0-16957] np: 1  1750403193.432022  1750403193.435282  (f:0 main)  (s:2 16945):  < pid: 16957 > is a BACKGROUND FORK
7
log.3[0-16958] np: 1  1750403193.432022  1750403193.435432  (f:0 main)  (s:2 16945):  < pid: 16958 > is a SUBSHELL
8
log.3[0-16957].0[0-16957] np: 1  1750403193.435923  1750403193.435988  (f:0 main)  (s:2 16945.16957):  < 'echo 7' > is a NORMAL COMMAND
log.3[0-16958].0[0-16958] np: 1  1750403193.436118  1750403193.436187  (f:0 main)  (s:2 16945.16958):  < 'echo 8' > is a NORMAL COMMAND
log.3[0-16959] np: 1  1750403193.432022  1750403193.437426  (f:0 main)  (s:2 16945):  < pid: 16959 > is a BACKGROUND FORK
log.3[0-16960] np: 1  1750403193.432022  1750403193.437631  (f:0 main)  (s:2 16945):  < pid: 16960 > is a BACKGROUND FORK
9.1
log.3[0-16961] np: 1  1750403193.432022  1750403193.438032  (f:0 main)  (s:2 16945):  < pid: 16961 > is a BACKGROUND FORK
log.3[0-16962] np: 1  1750403193.432022  1750403193.438210  (f:0 main)  (s:2 16945):  < pid: 16962 > is a BACKGROUND FORK
log.3[0-16960].0[0-16960] np: 1  1750403193.438547  1750403193.438617  (f:0 main)  (s:2 16945.16960):  < 'echo 9.1' > is a NORMAL COMMAND
9.1b
log.3[0-16945] np: 1  1750403193.432022  1750403193.438653  (f:0 main)  (s:1 16945):  < 'echo 4' > is a SIMPLE FORK
log.3[0-16959].0[0-16959] np: 1  1750403193.438332  1750403193.438684  (f:0 main)  (s:2 16945.16959):  < 'echo 9' > is a SIMPLE FORK *
11
log.3[0-16963] np: 1  1750403193.432022  1750403193.438661  (f:0 main)  (s:2 16945):  < pid: 16963 > is a BACKGROUND FORK
log.3[0-16962].0[0-16962] np: 1  1750403193.439167  1750403193.439229  (f:0 main)  (s:2 16945.16962):  < 'echo 9.1b' > is a NORMAL COMMAND
log.4[0-16945] np: 1  1750403193.439235  1750403193.439292  (f:0 main)  (s:1 16945):  < 'echo 11' > is a NORMAL COMMAND
log.3[0-16961].0[0-16961] np: 1  1750403193.438954  1750403193.439473  (f:0 main)  (s:2 16945.16961):  < 'echo 9.1a' > is a SIMPLE FORK *
9.2a
log.3[0-16960].1[0-16960] np: 1  1750403193.439167  1750403193.439614  (f:0 main)  (s:2 16945.16960):  < 'echo 9.2' > is a SIMPLE FORK
log.3[0-16963].0[0-16963] np: 1  1750403193.439563  1750403193.440035  (f:0 main)  (s:2 16945.16963):  < 'echo 9.1c' > is a SIMPLE FORK *
log.3[0-16965] np: 1  1750403193.432022  1750403193.439866  (f:0 main)  (s:2 16945):  < pid: 16965 > is a BACKGROUND FORK
9.2c
log.3[0-16961].1[0-16961] np: 1  1750403193.440111  1750403193.440174  (f:0 main)  (s:2 16945.16961):  < 'echo 9.2a' > is a NORMAL COMMAND
9.2
9.2b
9.1a
log.3[0-16964] np: 1  1750403193.432022  1750403193.440371  (f:0 main)  (s:2 16945):  < pid: 16964 > is a BACKGROUND FORK
9.999
9.1c
log.3[0-16963].1[0-16963] np: 1  1750403193.440600  1750403193.440665  (f:0 main)  (s:2 16945.16963):  < 'echo 9.2c' > is a NORMAL COMMAND
10
log.3[0-16965].0[0-16965] np: 1  1750403193.440655  1750403193.441078  (f:0 main)  (s:2 16945.16965):  < 'echo 10' > is a SIMPLE FORK *
12
9
log.3[0-16962].1[0-16962] np: 1  1750403193.439801  1750403193.440289  (f:0 main)  (s:2 16945.16962):  < 'echo 9.2b' > is a SIMPLE FORK
log.3[0-16964].0[0-16973] np: 1  1750403193.441206  1750403193.441850  (f:0 main)  (s:3 16945.16964):  < pid: 16973 > is a BACKGROUND FORK
log.5[0-16975] np: 1  1750403193.439880  1750403193.442408  (f:0 main)  (s:2 16945):  < pid: 16975 > is a BACKGROUND FORK
14
9.3
log.5[0-16974] np: 1  1750403193.439880  1750403193.442328  (f:0 main)  (s:2 16945):  < pid: 16974 > is a BACKGROUND FORK
log.5[0-16975].0[0-16975] np: 1  1750403193.443252  1750403193.443332  (f:0 main)  (s:2 16945.16975):  < 'echo 14' > is a NORMAL COMMAND
13
log.3[0-16964].0[0-16973].0[0-16973] np: 1  1750403193.442928  1750403193.443709  (f:0 main)  (s:3 16945.16964.16973):  < 'echo 9.3' > is a SIMPLE FORK
9.4
log.5[0-16974].0[0-16974] np: 1  1750403193.443726  1750403193.443793  (f:0 main)  (s:2 16945.16974):  < 'echo 13' > is a NORMAL COMMAND
log.5[0-16945] np: 1  1750403193.439880  1750403193.444043  (f:0 main)  (s:1 16945):  < 'echo 12' > is a SIMPLE FORK
log.3[0-16964].0[0-16973].1[0-16973] np: 1  1750403193.444276  1750403193.444344  (f:0 main)  (s:3 16945.16964.16973):  < 'echo 9.4' > is a NORMAL COMMAND
log.7.0[0-16945] np: 1  1750403193.444947  1750403193.444982  (f:2 main.ff)  (s:1 16945):  < 'ff 15' > is a FUNCTION (C)
15
log.3[0-16964].0[0-16964] np: 1  1750403193.441206  1750403193.445257  (f:0 main)  (s:2 16945.16964):  < 'echo 9.999' > is a NORMAL COMMAND
9.5
log.7.1[0-16945] np: 1  1750403193.445543  1750403193.445625  (f:2 main.ff)  (s:1 16945):  < 'echo "${*}"' > is a NORMAL COMMAND
log.3[0-16964].1[0-16964] np: 1  1750403193.445903  1750403193.445977  (f:0 main)  (s:2 16945.16964):  < 'echo 9.5' > is a NORMAL COMMAND
log.7[0-16945] np: 1  1750403193.444542  1750403193.448044  (f:0 main)  (s:1 16945):  < 'ff 15' > is a FUNCTION (P)
log.9.0[0-16945] np: 1  1750403193.448847  1750403193.448879  (f:2 main.gg)  (s:1 16945):  < 'gg 16' > is a FUNCTION (C)
16
log.9.1[0-16945] np: 1  1750403193.449236  1750403193.449279  (f:2 main.gg)  (s:1 16945):  < 'echo "$*"' > is a NORMAL COMMAND
log.9.3.0[0-16945] np: 1  1750403193.450063  1750403193.450095  (f:3 main.gg.ff)  (s:1 16945):  < 'ff "$@"' > is a FUNCTION (C)
16
log.9.3.1[0-16945] np: 1  1750403193.450412  1750403193.450458  (f:3 main.gg.ff)  (s:1 16945):  < 'echo "${*}"' > is a NORMAL COMMAND
log.9.3[0-16945] np: 1  1750403193.449623  1750403193.452247  (f:2 main.gg)  (s:1 16945):  < 'ff "$@"' > is a FUNCTION (P)
log.9[0-16977] np: 1  1750403193.448422  1750403193.454623  (f:0 main)  (s:2 16945):  < pid: 16977 > is a BACKGROUND FORK
a
log.9[1-1].0[1-16980] np: 1  1750403193.448422  1750403193.455147  (f:0 main)  (s:3 16945.1):  < pid: 16980 > is a BACKGROUND FORK
b
log.9[0-16979] np: 1  1750403193.448422  1750403193.455402  (f:0 main)  (s:2 16945):  < pid: 16979 > is a SUBSHELL
log.9[0-16977].0[0-16977] np: 1  1750403193.455507  1750403193.455923  (f:0 main)  (s:2 16945.16977):  < 'echo a' > is a SIMPLE FORK
A2
log.9[1-1].0[1-16980].0[1-16980] np: 1  1750403193.456124  1750403193.456196  (f:0 main)  (s:3 16945.1.16980):  < 'echo b' > is a NORMAL COMMAND
log.9[1-16979].0[1-16981].0[1-16982] np: 1  1750403193.448422  1750403193.455794  (f:0 main)  (s:4 16945.16979.16981):  < pid: 16982 > is a SUBSHELL
log.9[0-16979].0[0-16979] np: 1  1750403193.456246  1750403193.456639  (f:0 main)  (s:2 16945.16979):  < 'echo A2' > is a SIMPLE FORK
A1
A5
log.9[0-16979].1[0-16979] np: 1  1750403193.457176  1750403193.457248  (f:0 main)  (s:2 16945.16979):  < 'echo A1' > is a NORMAL COMMAND
log.9[1-16979].0[1-16981].0[1-16982].0[1-16982] np: 1  1750403193.456973  1750403193.457397  (f:0 main)  (s:4 16945.16979.16981.16982):  < 'echo A5' > is a SIMPLE FORK
log.9[0-16945] np: 1  1750403193.448422  1750403193.458159  (f:0 main)  (s:1 16945):  < 'gg 16' > is a FUNCTION (P)
log.9[1-1].0[1-16981] np: 1  1750403193.448422  1750403193.458619  (f:0 main)  (s:3 16945.1):  < pid: 16981 > is a BACKGROUND FORK
log.9[1-1].0[1-16981].0[1-16986] np: 1  1750403193.448422  1750403193.458680  (f:0 main)  (s:4 16945.1.16981):  < pid: 16986 > is a BACKGROUND FORK
A3
log.10[0-16945] np: 1  1750403193.458661  1750403193.459046  (f:0 main)  (s:1 16945):  < $'cat <<EOF\nfoo\nbar\nbaz\nEOF\n' > is a NORMAL COMMAND
A4
log.9[1-1].0[1-16981].0[1-16981] np: 1  1750403193.459493  1750403193.459561  (f:0 main)  (s:3 16945.1.16981):  < 'echo A3' > is a NORMAL COMMAND
log.9[1-1].0[1-16981].0[1-16986].0[1-16986] np: 1  1750403193.459531  1750403193.459611  (f:0 main)  (s:4 16945.1.16981.16986):  < 'echo A4' > is a NORMAL COMMAND
log.11[0-16945] np: 1  1750403193.459561  1750403193.459883  (f:0 main)  (s:1 16945):  < 'grep foo' > is a NORMAL COMMAND
log.12[0-16945] np: 1  1750403193.460442  1750403193.460829  (f:0 main)  (s:1 16945):  < 'sed '\''s/o/O/g'\''' > is a NORMAL COMMAND
1
log.13[0-16945] np: 4  1750403193.461460  1750403193.463429  (f:0 main)  (s:1 16945):  < 'wc -l' > is a NORMAL COMMAND
log.14[0-16991] np: 4  1750403193.463846  1750403193.464387  (f:0 main)  (s:2 16945):  < pid: 16991 > is a SUBSHELL
today is 2025-06-20
log.14[0-16945] np: 1  1750403193.463846  1750403193.466079  (f:0 main)  (s:1 16945):  < 'echo "today is $(date +%Y-%m-%d)"' > is a NORMAL COMMAND
log.15[0-16992] np: 1  1750403193.466506  1750403193.467445  (f:0 main)  (s:2 16945):  < pid: 16992 > is a SUBSHELL
log.15[1-16992].0[1-16993] np: 1  1750403193.466506  1750403193.467551  (f:0 main)  (s:3 16945.16992):  < pid: 16993 > is a SUBSHELL
log.15[1-16992].0[1-16993].0[1-16993] np: 1  1750403193.468350  1750403193.468424  (f:0 main)  (s:3 16945.16992.16993):  < 'echo nested' > is a NORMAL COMMAND
log.15[1-16992].0[1-16993].1[1-16993] np: 1  1750403193.468923  1750403193.468999  (f:0 main)  (s:3 16945.16992.16993):  < 'echo subshell' > is a NORMAL COMMAND
log.15[0-16992].0[0-16992] np: 2  1750403193.468068  1750403193.470256  (f:0 main)  (s:2 16945.16992):  < 'grep sub' > is a NORMAL COMMAND
log.15[0-16945] np: 1  1750403193.466506  1750403193.471340  (f:0 main)  (s:1 16945):  < 'x=$( ( echo nested; echo subshell ) | grep sub)' > is a NORMAL COMMAND
log.16[0-16995] np: 1  1750403193.471920  1750403193.472474  (f:0 main)  (s:2 16945):  < pid: 16995 > is a SUBSHELL
log.16[0-16996] np: 1  1750403193.471920  1750403193.472838  (f:0 main)  (s:2 16945):  < pid: 16996 > is a SUBSHELL
1,22c1,2
< bin
< boot
< dev
< etc
< home
< lib
< lib32
< lib64
< lib.usr-is-merged
< media
< mnt
< opt
< proc
< root
< run
< sbin
< script
< srv
< sys
< tmp
< usr
< var
---
> hsperfdata_root
> hsperfdata_runner61
log.16[0-16945] np: 1  1750403193.471920  1750403193.475509  (f:0 main)  (s:1 16945):  < 'diff <(ls /) <(ls /tmp)' > is a SIMPLE FORK
log.17[0-16998] np: 1  1750403193.475924  1750403193.476366  (f:0 main)  (s:2 16945):  < pid: 16998 > is a SUBSHELL
log.17[0-17000] np: 1  1750403193.475924  1750403193.478155  (f:0 main)  (s:2 16945):  < pid: 17000 > is a BACKGROUND FORK
log.17[0-16945] np: 1  1750403193.475924  1750403193.478115  (f:0 main)  (s:1 16945):  < 'grep pattern <(sed '\''s/^/>>/'\'' > /dev/null)' > is a SIMPLE FORK
log.17[0-17000].0[0-17000] np: 1  1750403193.478691  1750403193.478748  (f:0 main)  (s:2 16945.17000):  < 'for i in {1..3}' > is a NORMAL COMMAND
log.17[0-17000].1[0-17000] np: 1  1750403193.479286  1750403193.479355  (f:0 main)  (s:2 16945.17000):  < 'echo "$i"' > is a NORMAL COMMAND
log.18[0-16945] np: 1  1750403193.478798  1750403193.479389  (f:0 main)  (s:1 16945):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 1
log.19[0-16945] np: 1  1750403193.479998  1750403193.480048  (f:0 main)  (s:1 16945):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
log.17[0-17000].2[0-17000] np: 1  1750403193.479912  1750403193.491337  (f:0 main)  (s:2 16945.17000):  < 'sleep .01' > is a NORMAL COMMAND
log.17[0-17000].3[0-17000] np: 1  1750403193.491790  1750403193.491843  (f:0 main)  (s:2 16945.17000):  < 'for i in {1..3}' > is a NORMAL COMMAND
log.17[0-17000].4[0-17000] np: 1  1750403193.492376  1750403193.492423  (f:0 main)  (s:2 16945.17000):  < 'echo "$i"' > is a NORMAL COMMAND
log.20[0-16945] np: 1  1750403193.480538  1750403193.492529  (f:0 main)  (s:1 16945):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 2
log.21[0-16945] np: 1  1750403193.493266  1750403193.493343  (f:0 main)  (s:1 16945):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
log.17[0-17000].5[0-17000] np: 1  1750403193.492811  1750403193.504518  (f:0 main)  (s:2 16945.17000):  < 'sleep .01' > is a NORMAL COMMAND
log.17[0-17000].6[0-17000] np: 1  1750403193.505004  1750403193.505060  (f:0 main)  (s:2 16945.17000):  < 'for i in {1..3}' > is a NORMAL COMMAND
log.17[0-17000].7[0-17000] np: 1  1750403193.505650  1750403193.505718  (f:0 main)  (s:2 16945.17000):  < 'echo "$i"' > is a NORMAL COMMAND
log.22[0-16945] np: 1  1750403193.494142  1750403193.505790  (f:0 main)  (s:1 16945):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 3
log.23[0-16945] np: 1  1750403193.506584  1750403193.506655  (f:0 main)  (s:1 16945):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
log.17[0-17000].8[0-17000] np: 1  1750403193.506398  1750403193.517971  (f:0 main)  (s:2 16945.17000):  < 'sleep .01' > is a NORMAL COMMAND
log.24[0-16945] np: 1  1750403193.507347  1750403193.519014  (f:0 main)  (s:1 16945):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
log.25[0-16945] np: 1  1750403193.519705  1750403193.519766  (f:0 main)  (s:1 16945):  < 'let "x = 5 + 6"' > is a NORMAL COMMAND
log.26[0-16945] np: 1  1750403193.520241  1750403193.520314  (f:0 main)  (s:1 16945):  < 'arr=(one two three)' > is a NORMAL COMMAND
one two three
log.27[0-16945] np: 1  1750403193.520944  1750403193.521020  (f:0 main)  (s:1 16945):  < 'echo ${arr[@]}' > is a NORMAL COMMAND
log.28[0-16945] np: 1  1750403193.521695  1750403193.521754  (f:0 main)  (s:1 16945):  < '((i=0))' > is a NORMAL COMMAND
log.29[0-16945] np: 1  1750403193.522268  1750403193.522319  (f:0 main)  (s:1 16945):  < '((i<3))' > is a NORMAL COMMAND
0
log.30[0-16945] np: 1  1750403193.522882  1750403193.522963  (f:0 main)  (s:1 16945):  < 'echo "$i"' > is a NORMAL COMMAND
log.31[0-16945] np: 1  1750403193.523363  1750403193.523399  (f:0 main)  (s:1 16945):  < '((i++))' > is a NORMAL COMMAND
log.32[0-16945] np: 1  1750403193.523946  1750403193.524004  (f:0 main)  (s:1 16945):  < '((i<3))' > is a NORMAL COMMAND
1
log.33[0-16945] np: 1  1750403193.524671  1750403193.524743  (f:0 main)  (s:1 16945):  < 'echo "$i"' > is a NORMAL COMMAND
log.34[0-16945] np: 1  1750403193.525402  1750403193.525459  (f:0 main)  (s:1 16945):  < '((i++))' > is a NORMAL COMMAND
log.35[0-16945] np: 1  1750403193.526083  1750403193.526137  (f:0 main)  (s:1 16945):  < '((i<3))' > is a NORMAL COMMAND
2
log.36[0-16945] np: 1  1750403193.526768  1750403193.526839  (f:0 main)  (s:1 16945):  < 'echo "$i"' > is a NORMAL COMMAND
log.37[0-16945] np: 1  1750403193.527527  1750403193.527583  (f:0 main)  (s:1 16945):  < '((i++))' > is a NORMAL COMMAND
log.38[0-16945] np: 1  1750403193.528265  1750403193.528347  (f:0 main)  (s:1 16945):  < '((i<3))' > is a NORMAL COMMAND
log.39[0-16945] np: 1  1750403193.529029  1750403193.529086  (f:0 main)  (s:1 16945):  < 'cmd="echo inside-eval"' > is a NORMAL COMMAND
log.40[0-16945] np: 1  1750403193.529792  1750403193.529920  (f:0 main)  (s:1 16945):  < 'eval "$cmd"' > is a NORMAL COMMAND
inside-eval
log.41[0-16945] np: 1  1750403193.530462  1750403193.530512  (f:0 main)  (s:1 16945):  < 'echo inside-eval' > is a NORMAL COMMAND
log.42[0-16945] np: 1  1750403193.530942  1750403193.530988  (f:0 main)  (s:1 16945):  < 'eval "eval \"$cmd\""' > is a NORMAL COMMAND
log.43[0-16945] np: 1  1750403193.531616  1750403193.531681  (f:0 main)  (s:1 16945):  < 'eval "echo inside-eval"' > is a NORMAL COMMAND
inside-eval
log.44[0-16945] np: 1  1750403193.542158  1750403193.542237  (f:0 main)  (s:1 16945):  < 'kill -USR1 $BASHPID' > is a NORMAL COMMAND
got USR1
log.45[0-16945] np: 1  1750403193.542655  1750403193.542701  (f:0 main)  (s:1 16945):  < 'kill -USR1 $BASHPID' > is a NORMAL COMMAND
log.46[0-16945] np: 1  1750403193.549226  1750403193.561222  (f:0 main)  (s:1 16945):  < 'kill -USR1 $BASHPID' > is a NORMAL COMMAND
after-signal
log.47[0-16945] np: 1  1750403193.561981  1750403193.562058  (f:0 main)  (s:1 16945):  < 'echo after-signal' > is a NORMAL COMMAND
log.48[0-16945] np: 1  1750403193.562502  1750403193.562969  (f:0 main)  (s:1 16945):  < 'for i in {1..3}' > is a SIMPLE FORK
log.48[0-17005] np: 1  1750403193.562502  1750403193.563109  (f:0 main)  (s:2 16945):  < pid: 17005 > is a SUBSHELL
log.49[0-16945] np: 1  1750403193.563526  1750403193.564843  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.50[0-17006] np: 1  1750403193.565554  1750403193.566228  (f:0 main)  (s:2 16945):  < pid: 17006 > is a SUBSHELL
odd 1
log.50[0-17006].0[0-17006] np: 1  1750403193.566762  1750403193.566820  (f:0 main)  (s:2 16945.17006):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.50[0-16945] np: 1  1750403193.565554  1750403193.567704  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.51[0-16945] np: 1  1750403193.568183  1750403193.568261  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.52[0-16945] np: 1  1750403193.568784  1750403193.568824  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 2
log.53[0-16945] np: 1  1750403193.569251  1750403193.569320  (f:0 main)  (s:1 16945):  < 'echo even "$x"' > is a NORMAL COMMAND
log.54[0-16945] np: 1  1750403193.570005  1750403193.570069  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.55[0-17007] np: 1  1750403193.570534  1750403193.571251  (f:0 main)  (s:2 16945):  < pid: 17007 > is a SUBSHELL
odd 3
log.55[0-17007].0[0-17007] np: 1  1750403193.571822  1750403193.571878  (f:0 main)  (s:2 16945.17007):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.55[0-16945] np: 1  1750403193.570534  1750403193.572753  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.56[0-16945] np: 1  1750403193.573462  1750403193.573543  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.57[0-16945] np: 1  1750403193.574213  1750403193.574255  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 4
log.58[0-16945] np: 1  1750403193.574689  1750403193.574736  (f:0 main)  (s:1 16945):  < 'echo even "$x"' > is a NORMAL COMMAND
log.59[0-16945] np: 1  1750403193.575246  1750403193.575307  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.60[0-17008] np: 1  1750403193.575743  1750403193.576438  (f:0 main)  (s:2 16945):  < pid: 17008 > is a SUBSHELL
odd 5
log.60[0-17008].0[0-17008] np: 1  1750403193.577656  1750403193.577858  (f:0 main)  (s:2 16945.17008):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.60[0-16945] np: 1  1750403193.575743  1750403193.579341  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.61[0-16945] np: 1  1750403193.579936  1750403193.580023  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.62[0-16945] np: 1  1750403193.580673  1750403193.581142  (f:0 main)  (s:1 16945):  < 'for i in {1..3}' > is a SIMPLE FORK
log.62[0-17009] np: 1  1750403193.580673  1750403193.581278  (f:0 main)  (s:2 16945):  < pid: 17009 > is a SUBSHELL
log.63[0-16945] np: 1  1750403193.581751  1750403193.583128  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.64[0-17010] np: 1  1750403193.583686  1750403193.584290  (f:0 main)  (s:2 16945):  < pid: 17010 > is a SUBSHELL
odd 1
log.64[0-17010].0[0-17010] np: 1  1750403193.584946  1750403193.585016  (f:0 main)  (s:2 16945.17010):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.64[0-16945] np: 1  1750403193.583686  1750403193.585877  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.65[0-16945] np: 1  1750403193.586500  1750403193.586554  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.66[0-16945] np: 1  1750403193.587113  1750403193.587172  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 2
log.67[0-16945] np: 1  1750403193.587672  1750403193.587719  (f:0 main)  (s:1 16945):  < 'echo even "$x"' > is a NORMAL COMMAND
log.68[0-16945] np: 1  1750403193.588292  1750403193.588369  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.69[0-17011] np: 1  1750403193.588854  1750403193.589584  (f:0 main)  (s:2 16945):  < pid: 17011 > is a SUBSHELL
odd 3
log.69[0-17011].0[0-17011] np: 1  1750403193.590387  1750403193.590463  (f:0 main)  (s:2 16945.17011):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.69[0-16945] np: 1  1750403193.588854  1750403193.591351  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.70[0-16945] np: 1  1750403193.591943  1750403193.591996  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.71[0-16945] np: 1  1750403193.592424  1750403193.592462  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 4
log.72[0-16945] np: 1  1750403193.593009  1750403193.593053  (f:0 main)  (s:1 16945):  < 'echo even "$x"' > is a NORMAL COMMAND
log.73[0-16945] np: 1  1750403193.593573  1750403193.593619  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.74[0-17012] np: 1  1750403193.594257  1750403193.594930  (f:0 main)  (s:2 16945):  < pid: 17012 > is a SUBSHELL
odd 5
log.74[0-17012].0[0-17012] np: 1  1750403193.595786  1750403193.595861  (f:0 main)  (s:2 16945.17012):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.74[0-16945] np: 1  1750403193.594257  1750403193.596950  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.75[0-16945] np: 1  1750403193.597678  1750403193.597756  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.76[0-16945] np: 1  1750403193.598279  1750403193.598651  (f:0 main)  (s:1 16945):  < 'for i in {1..3}' > is a SIMPLE FORK
log.76[0-17013] np: 1  1750403193.598279  1750403193.598786  (f:0 main)  (s:2 16945):  < pid: 17013 > is a SUBSHELL
log.77[0-16945] np: 1  1750403193.599220  1750403193.600560  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.78[0-17014] np: 1  1750403193.601319  1750403193.601935  (f:0 main)  (s:2 16945):  < pid: 17014 > is a SUBSHELL
odd 1
log.78[0-17014].0[0-17014] np: 1  1750403193.602480  1750403193.602566  (f:0 main)  (s:2 16945.17014):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.78[0-16945] np: 1  1750403193.601319  1750403193.603505  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.79[0-16945] np: 1  1750403193.604074  1750403193.604142  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.80[0-16945] np: 1  1750403193.604716  1750403193.604777  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 2
log.81[0-16945] np: 1  1750403193.605413  1750403193.605483  (f:0 main)  (s:1 16945):  < 'echo even "$x"' > is a NORMAL COMMAND
log.82[0-16945] np: 1  1750403193.606147  1750403193.606215  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.83[0-17015] np: 1  1750403193.606945  1750403193.607547  (f:0 main)  (s:2 16945):  < pid: 17015 > is a SUBSHELL
odd 3
log.83[0-17015].0[0-17015] np: 1  1750403193.608291  1750403193.608355  (f:0 main)  (s:2 16945.17015):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.83[0-16945] np: 1  1750403193.606945  1750403193.609151  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.84[0-16945] np: 1  1750403193.609970  1750403193.610050  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.85[0-16945] np: 1  1750403193.610765  1750403193.610828  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 4
log.86[0-16945] np: 1  1750403193.611563  1750403193.611642  (f:0 main)  (s:1 16945):  < 'echo even "$x"' > is a NORMAL COMMAND
log.87[0-16945] np: 1  1750403193.612367  1750403193.612438  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND
log.88[0-17016] np: 1  1750403193.613169  1750403193.613744  (f:0 main)  (s:2 16945):  < pid: 17016 > is a SUBSHELL
odd 5
log.88[0-17016].0[0-17016] np: 1  1750403193.614399  1750403193.614486  (f:0 main)  (s:2 16945.17016):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.88[0-16945] np: 1  1750403193.613169  1750403193.615320  (f:0 main)  (s:1 16945):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.89[0-17017] np: 1    1750403193.622090  (f:0 main)  (s:2 16945):  < pid: 17017 > is a SUBSHELL
log.89[0-17017].0[0-17017] np: 1  1750403193.622545  1750403193.622594  (f:0 main)  (s:2 16945.17017):  < 'exit' > is a NORMAL COMMAND
bye
log.89[0-17018] np: 1    1750403193.631047  (f:0 main)  (s:2 16945):  < pid: 17018 > is a SUBSHELL
log.89[0-17018].1.0[0-17018] np: 1  1750403193.632318  1750403193.632386  (f:2 main.gg)  (s:2 16945.17018):  < 'gg 1' > is a FUNCTION (C)
1
log.89[0-17018].1.1[0-17018] np: 1  1750403193.632934  1750403193.633002  (f:2 main.gg)  (s:2 16945.17018):  < 'echo "$*"' > is a NORMAL COMMAND
log.89[0-17018].1.3.0[0-17018] np: 1  1750403193.634061  1750403193.634116  (f:3 main.gg.ff)  (s:2 16945.17018):  < 'ff "$@"' > is a FUNCTION (C)
1
log.89[0-17018].1.3.1[0-17018] np: 1  1750403193.634675  1750403193.634748  (f:3 main.gg.ff)  (s:2 16945.17018):  < 'echo "${*}"' > is a NORMAL COMMAND
bye
log.89[0-17018].1.3.2[0-17018] np: 1  1750403193.635283  1750403193.635347  (f:3 main.gg.ff)  (s:2 16945.17018):  < 'echo "${*}"' > is a NORMAL COMMAND
log.89[0-17018].1.3[0-17018] np: 1  1750403193.633500  1750403193.637789  (f:2 main.gg)  (s:2 16945.17018):  < 'ff "$@"' > is a FUNCTION (P)
bye
log.89[0-17018].1.4[0-17018] np: 1  1750403193.638167  1750403193.638230  (f:2 main.gg)  (s:2 16945.17018):  < 'echo "${*}"' > is a NORMAL COMMAND
log.89[0-17018].1[0-17018] np: 1  1750403193.631770  1750403193.639964  (f:0 main)  (s:2 16945.17018):  < 'gg 1' > is a FUNCTION (P)
log.89[0-17018].2[0-17018] np: 1  1750403193.640296  1750403193.640364  (f:0 main)  (s:2 16945.17018):  < 'exit' > is a NORMAL COMMAND
return
log.89[0-17019] np: 1    1750403193.651829  (f:0 main)  (s:2 16945):  < pid: 17019 > is a SUBSHELL
log.89[0-17019].1.0[0-17019] np: 1  1750403193.652761  1750403193.652794  (f:2 main.gg)  (s:2 16945.17019):  < 'gg 1' > is a FUNCTION (C)
1
log.89[0-17019].1.1[0-17019] np: 1  1750403193.653120  1750403193.653168  (f:2 main.gg)  (s:2 16945.17019):  < 'echo "$*"' > is a NORMAL COMMAND
log.89[0-17019].1.3.0[0-17019] np: 1  1750403193.653911  1750403193.653952  (f:3 main.gg.ff)  (s:2 16945.17019):  < 'ff "$@"' > is a FUNCTION (C)
1
log.89[0-17019].1.3.1[0-17019] np: 1  1750403193.654243  1750403193.654299  (f:3 main.gg.ff)  (s:2 16945.17019):  < 'echo "${*}"' > is a NORMAL COMMAND
return
log.89[0-17019].1.3.2[0-17019] np: 1  1750403193.654722  1750403193.654786  (f:3 main.gg.ff)  (s:2 16945.17019):  < 'echo "${*}"' > is a NORMAL COMMAND
log.89[0-17019].1.3[0-17019] np: 1  1750403193.653544  1750403193.656652  (f:2 main.gg)  (s:2 16945.17019):  < 'ff "$@"' > is a FUNCTION (P)
return
log.89[0-17019].1.4[0-17019] np: 1  1750403193.657065  1750403193.657113  (f:2 main.gg)  (s:2 16945.17019):  < 'echo "${*}"' > is a NORMAL COMMAND
log.89[0-17019].1[0-17019] np: 1  1750403193.652357  1750403193.659045  (f:0 main)  (s:2 16945.17019):  < 'gg 1' > is a FUNCTION (P)
log.89[0-17019].2[0-17019] np: 1  1750403193.659398  1750403193.659449  (f:0 main)  (s:2 16945.17019):  < 'exit' > is a NORMAL COMMAND
log.89[0-17020] np: 1    1750403193.669273  (f:0 main)  (s:2 16945):  < pid: 17020 > is a SUBSHELL
log.89[0-17020].0[0-17020] np: 1  1750403193.670033  1750403193.670099  (f:0 main)  (s:2 16945.17020):  < 'exit' > is a NORMAL COMMAND
log.89[0-17021] np: 1    1750403193.676251  (f:0 main)  (s:2 16945):  < pid: 17021 > is a SUBSHELL
log.89[0-17021].0[0-17021] np: 1  1750403193.676719  1750403193.676765  (f:0 main)  (s:2 16945.17021):  < 'exit' > is a NORMAL COMMAND
log.89[1-17022].0[1-17023].0[1-17024].0[1-17025] np: 1  1750403193.616036  1750403193.678918  (f:0 main)  (s:5 16945.17022.17023.17024):  < pid: 17025 > is a SUBSHELL
17025
log.89[1-17022].0[1-17023].0[1-17024].0[1-17025].0[1-17025] np: 1  1750403193.679783  1750403193.679848  (f:0 main)  (s:5 16945.17022.17023.17024.17025):  < 'echo $BASHPID' > is a NORMAL COMMAND
log.89[1-17022].0[1-17023].0[1-17024] np: 1  1750403193.616036  1750403193.680750  (f:0 main)  (s:4 16945.17022.17023):  < pid: 17024 > is a SUBSHELL
17024
log.89[1-17022].0[1-17023].0[1-17024].0[1-17024] np: 1  1750403193.681818  1750403193.681882  (f:0 main)  (s:4 16945.17022.17023.17024):  < 'echo $BASHPID' > is a NORMAL COMMAND
log.89[1-17022].0[1-17023] np: 1  1750403193.616036  1750403193.683223  (f:0 main)  (s:3 16945.17022):  < pid: 17023 > is a SUBSHELL
17023
log.89[1-17022].0[1-17023].0[1-17023] np: 1  1750403193.684324  1750403193.684437  (f:0 main)  (s:3 16945.17022.17023):  < 'echo $BASHPID' > is a NORMAL COMMAND
log.89[0-17022] np: 1  1750403193.616036  1750403193.685566  (f:0 main)  (s:2 16945):  < pid: 17022 > is a SUBSHELL
17022
log.89[0-17022].0[0-17022] np: 1  1750403193.686503  1750403193.686601  (f:0 main)  (s:2 16945.17022):  < 'echo $BASHPID' > is a NORMAL COMMAND
log.89[0-16945] np: 1  1750403193.616036  1750403193.687711  (f:0 main)  (s:1 16945):  < 'read x' > is a NORMAL COMMAND

```

####################################################################################
(
set -T
set -m

: &

read -r _ _ _ _ timep_PARENT_PGID _ _ timep_PARENT_TPID _ </proc/${BASHPID}/stat
timep_CHILD_PGID="$timep_PARENT_PGID"
timep_CHILD_TPID="$timep_PARENT_TPID"

timep_BASHPID_PREV="$BASHPID"
timep_BG_PID_PREV="$!"
timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
timep_SUBSHELL_BASHPID_CUR=''
timep_NEXEC_0=''
timep_NEXEC_A=('0')
timep_NPIDWRAP='0'
timep_BASHPID_STR="${BASHPID}"
timep_FUNCNAME_STR="main"

timep_SIMPLEFORK_NEXT_FLAG=false
timep_SIMPLEFORK_CUR_FLAG=false
timep_SKIP_DEBUG_FLAG=false
timep_NO_PRINT_FLAG=false
timep_IS_FUNC_FLAG_1=false

timep_BASH_COMMAND_PREV=()
timep_NPIPE=()
timep_STARTTIME=()

timep_FNEST=("${#FUNCNAME[@]}")
timep_FNEST_CUR="${#FUNCNAME[@]}"

timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]=''
timep_NPIPE[${timep_FNEST_CUR}]='0'
timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"

ff() { echo "${*}"; }

builtin trap - EXIT RETURN DEBUG

export -p timep_RETURN_TRAP_STR &>/dev/null && export -n timep_RETURN_TRAP_STR

declare -gxr timep_RETURN_TRAP_STR='timep_SKIP_DEBUG_FLAG=true
unset "timep_FNEST[-1]" "timep_NEXEC_A[-1]" "timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]" "timep_NPIPE[${timep_FNEST_CUR}]" "timep_STARTTIME[${timep_FNEST_CUR}]"
timep_NEXEC_0="${timep_NEXEC_0%.*}"
timep_FUNCNAME_STR="${timep_FUNCNAME_STR%.*}"
timep_FNEST_CUR="${timep_FNEST[-1]}"
timep_SKIP_DEBUG_FLAG=false'

export -p timep_DEBUG_TRAP_STR &>/dev/null && export -n timep_DEBUG_TRAP_STR
declare -agxr timep_DEBUG_TRAP_STR=('timep_NPIPE0="${#PIPESTATUS[@]}"
timep_ENDTIME0="${EPOCHREALTIME}"
' '
[[ "$-" == *m* ]] || { 
  printf '"'"'\nWARNING: timep requires job control to be enabled.\n         Running "set +m" is not allowed!\n         Job control will automatically be re-enabled.\n\n'"'"' >&2
  set -m
}
[[ "${BASH_COMMAND}" == trap\ * ]] && {
  timep_SKIP_DEBUG_FLAG=true
  (( timep_FNEST_CUR == ${#FUNCNAME[@]} )) && {
    timep_FNEST_CUR="${#FUNCNAME[@]}"
    timep_FNEST+=("${#FUNCNAME[@]}")
    timep_BASH_COMMAND_PREV+=("${BASH_COMMAND}")
    timep_FUNCNAME_STR+=".trap"
    timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
    timep_NEXEC_A+=("0")
  }
}
${timep_SKIP_DEBUG_FLAG} || {
timep_NPIPE[${timep_FNEST_CUR}]=${timep_NPIPE0}
timep_ENDTIME=${timep_ENDTIME0}
timep_IS_BG_FLAG=false
timep_IS_SUBSHELL_FLAG=false
timep_IS_FUNC_FLAG=false
timep_CMD_TYPE='"''"'
if ${timep_SIMPLEFORK_NEXT_FLAG}; then
  timep_SIMPLEFORK_NEXT_FLAG=false
  timep_SIMPLEFORK_CUR_FLAG=true
else
  timep_SIMPLEFORK_CUR_FLAG=false
fi
if (( timep_BASH_SUBSHELL_PREV == BASH_SUBSHELL )); then
  if (( timep_BG_PID_PREV == $! )); then
    (( timep_FNEST_CUR >= ${#FUNCNAME[@]} )) || {
      timep_NO_PRINT_FLAG=true
      timep_IS_FUNC_FLAG=true
      timep_FNEST+=("${#FUNCNAME[@]}")
    }
  else
    timep_IS_BG_FLAG=true
  fi
else
  timep_IS_SUBSHELL_FLAG=true
  (( BASHPID < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
  timep_SUBSHELL_BASHPID_CUR="$BASHPID"
  builtin trap '"'"':'"'"' EXIT
  read -r _ _ _ _ timep_CHILD_PGID _ _ timep_CHILD_TPID _ </proc/${BASHPID}/stat
  (( timep_CHILD_PGID == timep_PARENT_TPID )) || (( timep_CHILD_PGID == timep_CHILD_TPID )) || {  (( timep_CHILD_PGID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )); } || timep_IS_BG_FLAG=true
fi
if ${timep_IS_SUBSHELL_FLAG} && ${timep_IS_BG_FLAG}; then
  (( timep_CHILD_PGID == BASHPID )) && (( timep_CHILD_TPID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )) && timep_SIMPLEFORK_NEXT_FLAG=true
  timep_CMD_TYPE="BACKGROUND FORK"
elif ${timep_IS_SUBSHELL_FLAG}; then
  timep_CMD_TYPE="SUBSHELL"
elif [[ "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]}" == " (F) "* ]]; then
  timep_CMD_TYPE="FUNCTION (P)"
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]# (F) }"
elif ${timep_IS_BG_FLAG}; then
  timep_CMD_TYPE="SIMPLE FORK"
elif ${timep_IS_FUNC_FLAG_1}; then
  timep_CMD_TYPE="FUNCTION (C)"
  timep_IS_FUNC_FLAG_1=false
else
  timep_CMD_TYPE="NORMAL COMMAND"
fi
if ${timep_IS_SUBSHELL_FLAG}; then
  ${timep_NO_PRINT_FLAG} || printf '"'"'log%s.%s[%s-%s] np: %s  %s  %s  (f:%s %s)  (s:%s %s):  < pid: %s > is a %s\n'"'"' "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_NPIDWRAP}" "${BASHPID}" "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_STARTTIME[${timep_FNEST_CUR}]}" "${timep_ENDTIME}" "${timep_FNEST_CUR}" "${timep_FUNCNAME_STR}" "${BASH_SUBSHELL}" "${timep_BASHPID_STR}" "${BASHPID}" "${timep_CMD_TYPE}" >&${timep_FD}
  timep_BASHPID_STR+=".${BASHPID}"
  timep_NEXEC_0+=".${timep_NEXEC_A[-1]}[${timep_NPIDWRAP}-${BASHPID}]"
  timep_NEXEC_A+=(0)
  timep_PARENT_PGID="$timep_CHILD_PGID"
  timep_PARENT_TPID="$timep_CHILD_TPID"
  timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
elif [[ ${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]} ]]; then
  ${timep_SIMPLEFORK_CUR_FLAG} && (( BASHPID < $! )) && timep_CMD_TYPE="SIMPLE FORK *"
  ${timep_NO_PRINT_FLAG} || printf '"'"'log%s.%s[%s-%s] np: %s  %s  %s  (f:%s %s)  (s:%s %s):  < %s > is a %s\n'"'"' "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_NPIDWRAP}" "${BASHPID}" "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_STARTTIME[${timep_FNEST_CUR}]}" "${timep_ENDTIME}" "${timep_FNEST_CUR}" "${timep_FUNCNAME_STR}" "${BASH_SUBSHELL}" "${timep_BASHPID_STR}" "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]@Q}" "${timep_CMD_TYPE}" >&${timep_FD}
  (( timep_NEXEC_A[-1]++ ))
fi
if ${timep_IS_FUNC_FLAG}; then
  timep_FUNCNAME_STR+=".${FUNCNAME[0]}"
  timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
  timep_NEXEC_A+=(0)
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]=" (F) ${BASH_COMMAND}"
  timep_NPIPE[${#FUNCNAME[@]}]="${timep_NPIPE[${timep_FNEST_CUR}]}"
  timep_FNEST_CUR="${#FUNCNAME[@]}"
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${BASH_COMMAND}"
  timep_NO_PRINT_FLAG=false
  timep_IS_FUNC_FLAG_1=true
else
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="$BASH_COMMAND"
fi
timep_BG_PID_PREV="$!"
timep_BASHPID_PREV="$BASHPID"
timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"
}')

export timep_DEBUG_TRAP_STR

export -p -f trap &>/dev/null && export -n -f trap

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap "${trapStr}"':' EXIT ;;
            RETURN)  builtin trap "${trapStr}${timep_RETURN_TRAP_STR}" RETURN ;;
            DEBUG)   builtin trap "${timep_DEBUG_TRAP_STR[0]}${trapStr}${timep_DEBUG_TRAP_STR[1]}" DEBUG ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
}

export -f trap

builtin trap ':' EXIT
builtin trap "${timep_RETURN_TRAP_STR}" RETURN
builtin trap "${timep_DEBUG_TRAP_STR[0]}"$'\n'"${timep_DEBUG_TRAP_STR[1]}" DEBUG


gg() { echo "$*"; ff "$@"; }

{ echo ; } &
{ ( echo A & ); echo B; } &

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &

( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

trap 'echo got USR1; sleep .01' USR1
kill -USR1 $BASHPID
echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done

(
    trap 'echo bye' EXIT
    exit
)

(
    trap 'echo bye' RETURN EXIT
    gg 1
    exit
)

(
    trap 'echo exit' EXIT
    trap 'echo return' RETURN
    gg 1
    exit
)


(
    trap '' RETURN EXIT
    exit
)


(
    trap - EXIT
    exit
)

builtin trap - DEBUG EXIT RETURN

) {timep_FD}>&2


:<<'EOF'
0
log.0[0-446] np: 1  1750351101.303957  1750351101.304682  (f:0 main)  (s:2 444):  < pid: 446 > is a BACKGROUND FORK

log.0[0-444] np: 1  1750351101.305122  1750351101.305184  (f:0 main)  (s:1 444):  < 'echo 0' > is a NORMAL COMMAND
log.0[0-448] np: 1  1750351101.303957  1750351101.305023  (f:0 main)  (s:3 444):  < pid: 448 > is a BACKGROUND FORK
1
log.0[0-446].0[0-446] np: 1  1750351101.305367  1750351101.305422  (f:0 main)  (s:2 444.446):  < 'echo' > is a NORMAL COMMAND
A
log.0[0-448].0[0-448] np: 1  1750351101.305699  1750351101.306089  (f:0 main)  (s:3 444.448):  < 'echo A' > is a SIMPLE FORK
log.1[0-449] np: 1  1750351101.305627  1750351101.306125  (f:0 main)  (s:2 444):  < pid: 449 > is a SUBSHELL
2
log.0[0-447] np: 1  1750351101.303957  1750351101.306760  (f:0 main)  (s:2 444):  < pid: 447 > is a BACKGROUND FORK
log.1[0-449].0[0-449] np: 1  1750351101.306759  1750351101.306814  (f:0 main)  (s:2 444.449):  < 'echo 2' > is a NORMAL COMMAND
B
log.0[0-447].0[0-447] np: 1  1750351101.307252  1750351101.307290  (f:0 main)  (s:2 444.447):  < 'echo B' > is a NORMAL COMMAND
log.1[0-444] np: 1  1750351101.305627  1750351101.307555  (f:0 main)  (s:1 444):  < 'echo 1' > is a NORMAL COMMAND
3
log.2[0-444] np: 1  1750351101.307937  1750351101.308270  (f:0 main)  (s:1 444):  < 'echo 3' > is a SIMPLE FORK
4
log.3[0-453] np: 1  1750351101.308673  1750351101.309213  (f:0 main)  (s:2 444):  < pid: 453 > is a BACKGROUND FORK
5
log.3[0-453].0[0-453] np: 1  1750351101.309594  1750351101.309644  (f:0 main)  (s:2 444.453):  < 'echo 5' > is a NORMAL COMMAND
log.3[0-454] np: 1  1750351101.308673  1750351101.309397  (f:0 main)  (s:2 444):  < pid: 454 > is a SUBSHELL
6
log.3[0-454].0[0-454] np: 1  1750351101.310026  1750351101.310379  (f:0 main)  (s:2 444.454):  < 'echo 6' > is a SIMPLE FORK
log.3[0-456] np: 1  1750351101.308673  1750351101.311449  (f:0 main)  (s:2 444):  < pid: 456 > is a BACKGROUND FORK
7
log.3[0-457] np: 1  1750351101.308673  1750351101.311603  (f:0 main)  (s:2 444):  < pid: 457 > is a SUBSHELL
log.3[0-456].0[0-456] np: 1  1750351101.311883  1750351101.311923  (f:0 main)  (s:2 444.456):  < 'echo 7' > is a NORMAL COMMAND
8
log.3[0-457].0[0-457] np: 1  1750351101.312174  1750351101.312237  (f:0 main)  (s:2 444.457):  < 'echo 8' > is a NORMAL COMMAND
log.3[0-458] np: 1  1750351101.308673  1750351101.313297  (f:0 main)  (s:2 444):  < pid: 458 > is a BACKGROUND FORK
log.3[0-459] np: 1  1750351101.308673  1750351101.313419  (f:0 main)  (s:2 444):  < pid: 459 > is a BACKGROUND FORK
9.1
log.3[0-460] np: 1  1750351101.308673  1750351101.313633  (f:0 main)  (s:2 444):  < pid: 460 > is a BACKGROUND FORK
log.3[0-459].0[0-459] np: 1  1750351101.314014  1750351101.314076  (f:0 main)  (s:2 444.459):  < 'echo 9.1' > is a NORMAL COMMAND
log.3[0-462] np: 1  1750351101.308673  1750351101.313968  (f:0 main)  (s:2 444):  < pid: 462 > is a BACKGROUND FORK
log.3[0-458].0[0-458] np: 1  1750351101.313893  1750351101.314223  (f:0 main)  (s:2 444.458):  < 'echo 9' > is a SIMPLE FORK *
log.3[0-444] np: 1  1750351101.308673  1750351101.314288  (f:0 main)  (s:1 444):  < 'echo 4' > is a SIMPLE FORK
11
log.3[0-460].0[0-460] np: 1  1750351101.314224  1750351101.314512  (f:0 main)  (s:2 444.460):  < 'echo 9.1a' > is a SIMPLE FORK *
9.2a
log.3[0-459].1[0-459] np: 1  1750351101.314473  1750351101.314766  (f:0 main)  (s:2 444.459):  < 'echo 9.2' > is a SIMPLE FORK
9
log.3[0-465] np: 1  1750351101.308673  1750351101.314678  (f:0 main)  (s:2 444):  < pid: 465 > is a BACKGROUND FORK
log.4[0-444] np: 1  1750351101.314728  1750351101.314777  (f:0 main)  (s:1 444):  < 'echo 11' > is a NORMAL COMMAND
log.3[0-462].0[0-462] np: 1  1750351101.314553  1750351101.314840  (f:0 main)  (s:2 444.462):  < 'echo 9.1c' > is a SIMPLE FORK *
9.2c
log.3[0-460].1[0-460] np: 1  1750351101.314944  1750351101.314991  (f:0 main)  (s:2 444.460):  < 'echo 9.2a' > is a NORMAL COMMAND
log.3[0-463] np: 1  1750351101.308673  1750351101.315083  (f:0 main)  (s:2 444):  < pid: 463 > is a BACKGROUND FORK
9.999
9.1a
9.2
12
log.3[0-465].0[0-465] np: 1  1750351101.315291  1750351101.315625  (f:0 main)  (s:2 444.465):  < 'echo 10' > is a SIMPLE FORK *
9.1c
log.3[0-461] np: 1  1750351101.308673  1750351101.313795  (f:0 main)  (s:2 444):  < pid: 461 > is a BACKGROUND FORK
10
9.1b
log.3[0-462].1[0-462] np: 1  1750351101.315301  1750351101.315347  (f:0 main)  (s:2 444.462):  < 'echo 9.2c' > is a NORMAL COMMAND
log.5[0-471] np: 1  1750351101.315288  1750351101.316104  (f:0 main)  (s:2 444):  < pid: 471 > is a BACKGROUND FORK
13
log.3[0-461].0[0-461] np: 1  1750351101.316249  1750351101.316302  (f:0 main)  (s:2 444.461):  < 'echo 9.1b' > is a NORMAL COMMAND
log.3[0-463].0[0-472] np: 1  1750351101.315614  1750351101.316600  (f:0 main)  (s:3 444.463):  < pid: 472 > is a BACKGROUND FORK
9.2b
log.5[0-473] np: 1  1750351101.315288  1750351101.316964  (f:0 main)  (s:2 444):  < pid: 473 > is a BACKGROUND FORK
log.5[0-471].0[0-471] np: 1  1750351101.316653  1750351101.317171  (f:0 main)  (s:2 444.471):  < 'echo 13' > is a NORMAL COMMAND
9.3
14
log.5[0-473].0[0-473] np: 1  1750351101.317548  1750351101.317599  (f:0 main)  (s:2 444.473):  < 'echo 14' > is a NORMAL COMMAND
log.3[0-461].1[0-461] np: 1  1750351101.317182  1750351101.317493  (f:0 main)  (s:2 444.461):  < 'echo 9.2b' > is a SIMPLE FORK
log.3[0-463].0[0-472].0[0-472] np: 1  1750351101.317257  1750351101.317577  (f:0 main)  (s:3 444.463.472):  < 'echo 9.3' > is a SIMPLE FORK
9.4
log.5[0-444] np: 1  1750351101.315288  1750351101.318165  (f:0 main)  (s:1 444):  < 'echo 12' > is a SIMPLE FORK
log.3[0-463].0[0-472].1[0-472] np: 1  1750351101.318011  1750351101.318079  (f:0 main)  (s:3 444.463.472):  < 'echo 9.4' > is a NORMAL COMMAND
log.7.0[0-444] np: 1  1750351101.318715  1750351101.318738  (f:2 main.ff)  (s:1 444):  < 'ff 15' > is a FUNCTION (C)
15
log.3[0-463].0[0-463] np: 1  1750351101.315614  1750351101.318778  (f:0 main)  (s:2 444.463):  < 'echo 9.999' > is a NORMAL COMMAND
9.5
log.7.1[0-444] np: 1  1750351101.318983  1750351101.319027  (f:2 main.ff)  (s:1 444):  < 'echo "${*}"' > is a NORMAL COMMAND
log.3[0-463].1[0-463] np: 1  1750351101.319088  1750351101.319130  (f:0 main)  (s:2 444.463):  < 'echo 9.5' > is a NORMAL COMMAND
log.7[0-444] np: 1  1750351101.318437  1750351101.320348  (f:0 main)  (s:1 444):  < 'ff 15' > is a FUNCTION (P)
log.9.0[0-444] np: 1  1750351101.320880  1750351101.320910  (f:2 main.gg)  (s:1 444):  < 'gg 16' > is a FUNCTION (C)
16
log.9.1[0-444] np: 1  1750351101.321173  1750351101.321217  (f:2 main.gg)  (s:1 444):  < 'echo "$*"' > is a NORMAL COMMAND
log.9.3.0[0-444] np: 1  1750351101.321844  1750351101.321867  (f:3 main.gg.ff)  (s:1 444):  < 'ff "$@"' > is a FUNCTION (C)
16
log.9.3.1[0-444] np: 1  1750351101.322144  1750351101.322193  (f:3 main.gg.ff)  (s:1 444):  < 'echo "${*}"' > is a NORMAL COMMAND
log.9.3[0-444] np: 1  1750351101.321544  1750351101.323435  (f:2 main.gg)  (s:1 444):  < 'ff "$@"' > is a FUNCTION (P)
log.9[0-476] np: 1  1750351101.320627  1750351101.325247  (f:0 main)  (s:2 444):  < pid: 476 > is a BACKGROUND FORK
a
log.9[0-479] np: 1  1750351101.320627  1750351101.325620  (f:0 main)  (s:3 444):  < pid: 479 > is a BACKGROUND FORK
b
log.9[0-478] np: 1  1750351101.320627  1750351101.325754  (f:0 main)  (s:2 444):  < pid: 478 > is a SUBSHELL
log.9[0-476].0[0-476] np: 1  1750351101.325675  1750351101.325984  (f:0 main)  (s:2 444.476):  < 'echo a' > is a SIMPLE FORK
log.9[0-479].0[0-479] np: 1  1750351101.326170  1750351101.326223  (f:0 main)  (s:3 444.479):  < 'echo b' > is a NORMAL COMMAND
A2
log.9[0-482] np: 1  1750351101.320627  1750351101.326159  (f:0 main)  (s:4 444):  < pid: 482 > is a SUBSHELL
A5
log.9[0-478].0[0-478] np: 1  1750351101.326355  1750351101.326645  (f:0 main)  (s:2 444.478):  < 'echo A2' > is a SIMPLE FORK
A1
log.9[0-482].0[0-482] np: 1  1750351101.326722  1750351101.327029  (f:0 main)  (s:4 444.482):  < 'echo A5' > is a SIMPLE FORK
log.9[0-478].1[0-478] np: 1  1750351101.327102  1750351101.327158  (f:0 main)  (s:2 444.478):  < 'echo A1' > is a NORMAL COMMAND
log.9[0-485] np: 1  1750351101.320627  1750351101.327917  (f:0 main)  (s:4 444):  < pid: 485 > is a BACKGROUND FORK
A4
log.9[0-444] np: 1  1750351101.320627  1750351101.327897  (f:0 main)  (s:1 444):  < 'gg 16' > is a FUNCTION (P)
log.9[0-480] np: 1  1750351101.320627  1750351101.327916  (f:0 main)  (s:3 444):  < pid: 480 > is a BACKGROUND FORK
A3
log.9[0-485].0[0-485] np: 1  1750351101.328358  1750351101.328401  (f:0 main)  (s:4 444.485):  < 'echo A4' > is a NORMAL COMMAND
log.9[0-480].0[0-480] np: 1  1750351101.328500  1750351101.328552  (f:0 main)  (s:3 444.480):  < 'echo A3' > is a NORMAL COMMAND
log.10[0-444] np: 1  1750351101.328436  1750351101.328747  (f:0 main)  (s:1 444):  < $'cat <<EOF\nfoo\nbar\nbaz\nEOF\n' > is a NORMAL COMMAND
log.11[0-444] np: 1  1750351101.329221  1750351101.329443  (f:0 main)  (s:1 444):  < 'grep foo' > is a NORMAL COMMAND
log.12[0-444] np: 1  1750351101.329751  1750351101.330007  (f:0 main)  (s:1 444):  < 'sed '\''s/o/O/g'\''' > is a NORMAL COMMAND
1
log.13[0-444] np: 4  1750351101.330448  1750351101.333144  (f:0 main)  (s:1 444):  < 'wc -l' > is a NORMAL COMMAND
log.14[0-490] np: 4  1750351101.333677  1750351101.334105  (f:0 main)  (s:2 444):  < pid: 490 > is a SUBSHELL
today is 2025-06-19
log.14[0-444] np: 1  1750351101.333677  1750351101.337348  (f:0 main)  (s:1 444):  < 'echo "today is $(date +%Y-%m-%d)"' > is a NORMAL COMMAND
log.15[0-492] np: 1  1750351101.337654  1750351101.338355  (f:0 main)  (s:3 444):  < pid: 492 > is a SUBSHELL
log.15[0-491] np: 1  1750351101.337654  1750351101.338309  (f:0 main)  (s:2 444):  < pid: 491 > is a SUBSHELL
log.15[0-492].0[0-492] np: 1  1750351101.338911  1750351101.338965  (f:0 main)  (s:3 444.492):  < 'echo nested' > is a NORMAL COMMAND
log.15[0-492].1[0-492] np: 1  1750351101.339336  1750351101.339369  (f:0 main)  (s:3 444.492):  < 'echo subshell' > is a NORMAL COMMAND
log.15[0-491].0[0-491] np: 2  1750351101.338926  1750351101.340630  (f:0 main)  (s:2 444.491):  < 'grep sub' > is a NORMAL COMMAND
log.15[0-444] np: 1  1750351101.337654  1750351101.341180  (f:0 main)  (s:1 444):  < 'x=$( ( echo nested; echo subshell ) | grep sub)' > is a NORMAL COMMAND
log.16[0-494] np: 1  1750351101.341588  1750351101.341973  (f:0 main)  (s:2 444):  < pid: 494 > is a SUBSHELL
log.16[0-495] np: 1  1750351101.341588  1750351101.342212  (f:0 main)  (s:2 444):  < pid: 495 > is a SUBSHELL
1,22c1
< bin
< boot
< dev
< etc
< home
< lib
< lib32
< lib64
< lib.usr-is-merged
< media
< mnt
< opt
< proc
< root
< run
< sbin
< script
< srv
< sys
< tmp
< usr
< var
---
> hsperfdata_runner90
log.16[0-444] np: 1  1750351101.341588  1750351101.345669  (f:0 main)  (s:1 444):  < 'diff <(ls /) <(ls /tmp)' > is a SIMPLE FORK
log.17[0-497] np: 1  1750351101.346027  1750351101.346445  (f:0 main)  (s:2 444):  < pid: 497 > is a SUBSHELL
log.17[0-444] np: 1  1750351101.346027  1750351101.347767  (f:0 main)  (s:1 444):  < 'grep pattern <(sed '\''s/^/>>/'\'' > /dev/null)' > is a SIMPLE FORK
log.17[0-499] np: 1  1750351101.346027  1750351101.347820  (f:0 main)  (s:2 444):  < pid: 499 > is a BACKGROUND FORK
log.17[0-499].0[0-499] np: 1  1750351101.348647  1750351101.348684  (f:0 main)  (s:2 444.499):  < 'for i in {1..3}' > is a NORMAL COMMAND
log.17[0-499].1[0-499] np: 1  1750351101.349066  1750351101.349114  (f:0 main)  (s:2 444.499):  < 'echo "$i"' > is a NORMAL COMMAND
log.18[0-444] np: 1  1750351101.348567  1750351101.349134  (f:0 main)  (s:1 444):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 1
log.19[0-444] np: 1  1750351101.349639  1750351101.349691  (f:0 main)  (s:1 444):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
log.17[0-499].2[0-499] np: 1  1750351101.349548  1750351101.362099  (f:0 main)  (s:2 444.499):  < 'sleep .01' > is a NORMAL COMMAND
log.17[0-499].3[0-499] np: 1  1750351101.362459  1750351101.362489  (f:0 main)  (s:2 444.499):  < 'for i in {1..3}' > is a NORMAL COMMAND
log.17[0-499].4[0-499] np: 1  1750351101.362825  1750351101.362868  (f:0 main)  (s:2 444.499):  < 'echo "$i"' > is a NORMAL COMMAND
log.20[0-444] np: 1  1750351101.350176  1750351101.362946  (f:0 main)  (s:1 444):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 2
log.21[0-444] np: 1  1750351101.363449  1750351101.363498  (f:0 main)  (s:1 444):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
log.17[0-499].5[0-499] np: 1  1750351101.363349  1750351101.374672  (f:0 main)  (s:2 444.499):  < 'sleep .01' > is a NORMAL COMMAND
log.17[0-499].6[0-499] np: 1  1750351101.375137  1750351101.375168  (f:0 main)  (s:2 444.499):  < 'for i in {1..3}' > is a NORMAL COMMAND
log.17[0-499].7[0-499] np: 1  1750351101.375438  1750351101.375478  (f:0 main)  (s:2 444.499):  < 'echo "$i"' > is a NORMAL COMMAND
log.22[0-444] np: 1  1750351101.363907  1750351101.375535  (f:0 main)  (s:1 444):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 3
log.23[0-444] np: 1  1750351101.376039  1750351101.376104  (f:0 main)  (s:1 444):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
log.17[0-499].8[0-499] np: 1  1750351101.375992  1750351101.387528  (f:0 main)  (s:2 444.499):  < 'sleep .01' > is a NORMAL COMMAND
log.24[0-444] np: 1  1750351101.376480  1750351101.388317  (f:0 main)  (s:1 444):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
log.25[0-444] np: 1  1750351101.388742  1750351101.388789  (f:0 main)  (s:1 444):  < 'let "x = 5 + 6"' > is a NORMAL COMMAND
log.26[0-444] np: 1  1750351101.389098  1750351101.389145  (f:0 main)  (s:1 444):  < 'arr=(one two three)' > is a NORMAL COMMAND
one two three
log.27[0-444] np: 1  1750351101.389432  1750351101.389481  (f:0 main)  (s:1 444):  < 'echo ${arr[@]}' > is a NORMAL COMMAND
log.28[0-444] np: 1  1750351101.389837  1750351101.389880  (f:0 main)  (s:1 444):  < '((i=0))' > is a NORMAL COMMAND
log.29[0-444] np: 1  1750351101.390191  1750351101.390221  (f:0 main)  (s:1 444):  < '((i<3))' > is a NORMAL COMMAND
0
log.30[0-444] np: 1  1750351101.390489  1750351101.390522  (f:0 main)  (s:1 444):  < 'echo "$i"' > is a NORMAL COMMAND
log.31[0-444] np: 1  1750351101.390866  1750351101.390910  (f:0 main)  (s:1 444):  < '((i++))' > is a NORMAL COMMAND
log.32[0-444] np: 1  1750351101.391260  1750351101.391303  (f:0 main)  (s:1 444):  < '((i<3))' > is a NORMAL COMMAND
1
log.33[0-444] np: 1  1750351101.391585  1750351101.391631  (f:0 main)  (s:1 444):  < 'echo "$i"' > is a NORMAL COMMAND
log.34[0-444] np: 1  1750351101.391947  1750351101.391987  (f:0 main)  (s:1 444):  < '((i++))' > is a NORMAL COMMAND
log.35[0-444] np: 1  1750351101.392294  1750351101.392321  (f:0 main)  (s:1 444):  < '((i<3))' > is a NORMAL COMMAND
2
log.36[0-444] np: 1  1750351101.392579  1750351101.392611  (f:0 main)  (s:1 444):  < 'echo "$i"' > is a NORMAL COMMAND
log.37[0-444] np: 1  1750351101.392936  1750351101.392975  (f:0 main)  (s:1 444):  < '((i++))' > is a NORMAL COMMAND
log.38[0-444] np: 1  1750351101.393329  1750351101.393378  (f:0 main)  (s:1 444):  < '((i<3))' > is a NORMAL COMMAND
log.39[0-444] np: 1  1750351101.393661  1750351101.393691  (f:0 main)  (s:1 444):  < 'cmd="echo inside-eval"' > is a NORMAL COMMAND
log.40[0-444] np: 1  1750351101.394028  1750351101.408070  (f:0 main)  (s:1 444):  < 'eval "$cmd"' > is a NORMAL COMMAND
inside-eval
log.41[0-444] np: 1  1750351101.408520  1750351101.408560  (f:0 main)  (s:1 444):  < 'echo inside-eval' > is a NORMAL COMMAND
log.42[0-444] np: 1  1750351101.408882  1750351101.408931  (f:0 main)  (s:1 444):  < 'eval "eval \"$cmd\""' > is a NORMAL COMMAND
log.43[0-444] np: 1  1750351101.409338  1750351101.409386  (f:0 main)  (s:1 444):  < 'eval "echo inside-eval"' > is a NORMAL COMMAND
inside-eval
log.44[0-444] np: 1  1750351101.415981  1750351101.416024  (f:0 main)  (s:1 444):  < 'kill -USR1 $BASHPID' > is a NORMAL COMMAND
got USR1
log.45[0-444] np: 1  1750351101.416464  1750351101.416517  (f:0 main)  (s:1 444):  < 'kill -USR1 $BASHPID' > is a NORMAL COMMAND
log.46[0-444] np: 1  1750351101.416813  1750351101.427985  (f:0 main)  (s:1 444):  < 'kill -USR1 $BASHPID' > is a NORMAL COMMAND
after-signal
log.47[0-444] np: 1  1750351101.428462  1750351101.428504  (f:0 main)  (s:1 444):  < 'echo after-signal' > is a NORMAL COMMAND
log.48[0-444] np: 1  1750351101.428786  1750351101.429077  (f:0 main)  (s:1 444):  < 'for i in {1..3}' > is a SIMPLE FORK
log.48[0-504] np: 1  1750351101.428786  1750351101.429136  (f:0 main)  (s:2 444):  < pid: 504 > is a SUBSHELL
log.49[0-444] np: 1  1750351101.429556  1750351101.431985  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.50[0-505] np: 1  1750351101.432505  1750351101.432925  (f:0 main)  (s:2 444):  < pid: 505 > is a SUBSHELL
odd 1
log.50[0-505].0[0-505] np: 1  1750351101.433472  1750351101.433530  (f:0 main)  (s:2 444.505):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.50[0-444] np: 1  1750351101.432505  1750351101.434102  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.51[0-444] np: 1  1750351101.434633  1750351101.434686  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.52[0-444] np: 1  1750351101.435138  1750351101.435189  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 2
log.53[0-444] np: 1  1750351101.435616  1750351101.435666  (f:0 main)  (s:1 444):  < 'echo even "$x"' > is a NORMAL COMMAND
log.54[0-444] np: 1  1750351101.436124  1750351101.436169  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.55[0-506] np: 1  1750351101.436475  1750351101.436890  (f:0 main)  (s:2 444):  < pid: 506 > is a SUBSHELL
odd 3
log.55[0-506].0[0-506] np: 1  1750351101.437353  1750351101.437392  (f:0 main)  (s:2 444.506):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.55[0-444] np: 1  1750351101.436475  1750351101.437849  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.56[0-444] np: 1  1750351101.438231  1750351101.438267  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.57[0-444] np: 1  1750351101.438584  1750351101.438612  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 4
log.58[0-444] np: 1  1750351101.438887  1750351101.438929  (f:0 main)  (s:1 444):  < 'echo even "$x"' > is a NORMAL COMMAND
log.59[0-444] np: 1  1750351101.439291  1750351101.439324  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.60[0-507] np: 1  1750351101.439602  1750351101.439988  (f:0 main)  (s:2 444):  < pid: 507 > is a SUBSHELL
odd 5
log.60[0-507].0[0-507] np: 1  1750351101.440528  1750351101.440582  (f:0 main)  (s:2 444.507):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.60[0-444] np: 1  1750351101.439602  1750351101.441251  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.61[0-444] np: 1  1750351101.441576  1750351101.441618  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.62[0-444] np: 1  1750351101.441969  1750351101.442301  (f:0 main)  (s:1 444):  < 'for i in {1..3}' > is a SIMPLE FORK
log.62[0-508] np: 1  1750351101.441969  1750351101.442337  (f:0 main)  (s:2 444):  < pid: 508 > is a SUBSHELL
log.63[0-444] np: 1  1750351101.442866  1750351101.443795  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.64[0-509] np: 1  1750351101.444246  1750351101.444713  (f:0 main)  (s:2 444):  < pid: 509 > is a SUBSHELL
odd 1
log.64[0-509].0[0-509] np: 1  1750351101.445153  1750351101.445199  (f:0 main)  (s:2 444.509):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.64[0-444] np: 1  1750351101.444246  1750351101.445751  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.65[0-444] np: 1  1750351101.446190  1750351101.446228  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.66[0-444] np: 1  1750351101.446539  1750351101.446581  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 2
log.67[0-444] np: 1  1750351101.446880  1750351101.446916  (f:0 main)  (s:1 444):  < 'echo even "$x"' > is a NORMAL COMMAND
log.68[0-444] np: 1  1750351101.447207  1750351101.447240  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.69[0-510] np: 1  1750351101.447501  1750351101.447900  (f:0 main)  (s:2 444):  < pid: 510 > is a SUBSHELL
odd 3
log.69[0-510].0[0-510] np: 1  1750351101.448441  1750351101.448495  (f:0 main)  (s:2 444.510):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.69[0-444] np: 1  1750351101.447501  1750351101.449139  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.70[0-444] np: 1  1750351101.449621  1750351101.449675  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.71[0-444] np: 1  1750351101.450124  1750351101.450174  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 4
log.72[0-444] np: 1  1750351101.450632  1750351101.450694  (f:0 main)  (s:1 444):  < 'echo even "$x"' > is a NORMAL COMMAND
log.73[0-444] np: 1  1750351101.451191  1750351101.451251  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.74[0-511] np: 1  1750351101.451715  1750351101.452183  (f:0 main)  (s:2 444):  < pid: 511 > is a SUBSHELL
odd 5
log.74[0-511].0[0-511] np: 1  1750351101.452718  1750351101.452770  (f:0 main)  (s:2 444.511):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.74[0-444] np: 1  1750351101.451715  1750351101.453491  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.75[0-444] np: 1  1750351101.454046  1750351101.454118  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.76[0-512] np: 1  1750351101.454599  1750351101.454966  (f:0 main)  (s:2 444):  < pid: 512 > is a SUBSHELL
log.76[0-444] np: 1  1750351101.454599  1750351101.454940  (f:0 main)  (s:1 444):  < 'for i in {1..3}' > is a SIMPLE FORK
log.77[0-444] np: 1  1750351101.455518  1750351101.456370  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.78[0-513] np: 1  1750351101.456830  1750351101.457238  (f:0 main)  (s:2 444):  < pid: 513 > is a SUBSHELL
odd 1
log.78[0-513].0[0-513] np: 1  1750351101.457685  1750351101.457733  (f:0 main)  (s:2 444.513):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.78[0-444] np: 1  1750351101.456830  1750351101.458250  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.79[0-444] np: 1  1750351101.458689  1750351101.458732  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.80[0-444] np: 1  1750351101.459019  1750351101.459047  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 2
log.81[0-444] np: 1  1750351101.459349  1750351101.459390  (f:0 main)  (s:1 444):  < 'echo even "$x"' > is a NORMAL COMMAND
log.82[0-444] np: 1  1750351101.459805  1750351101.459844  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.83[0-514] np: 1  1750351101.460138  1750351101.460499  (f:0 main)  (s:2 444):  < pid: 514 > is a SUBSHELL
odd 3
log.83[0-514].0[0-514] np: 1  1750351101.460950  1750351101.460998  (f:0 main)  (s:2 444.514):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.83[0-444] np: 1  1750351101.460138  1750351101.461535  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.84[0-444] np: 1  1750351101.461945  1750351101.461981  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.85[0-444] np: 1  1750351101.462287  1750351101.462315  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 4
log.86[0-444] np: 1  1750351101.462585  1750351101.462619  (f:0 main)  (s:1 444):  < 'echo even "$x"' > is a NORMAL COMMAND
log.87[0-444] np: 1  1750351101.463017  1750351101.463085  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND
log.88[0-515] np: 1  1750351101.463494  1750351101.463895  (f:0 main)  (s:2 444):  < pid: 515 > is a SUBSHELL
odd 5
log.88[0-515].0[0-515] np: 1  1750351101.464323  1750351101.464360  (f:0 main)  (s:2 444.515):  < 'echo odd "$x"' > is a NORMAL COMMAND
log.88[0-444] np: 1  1750351101.463494  1750351101.464810  (f:0 main)  (s:1 444):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
log.89[0-516] np: 1    1750351101.468758  (f:0 main)  (s:2 444):  < pid: 516 > is a SUBSHELL
log.89[0-516].0[0-516] np: 1  1750351101.469099  1750351101.469132  (f:0 main)  (s:2 444.516):  < 'exit' > is a NORMAL COMMAND
bye
log.89[0-517] np: 1    1750351101.473963  (f:0 main)  (s:2 444):  < pid: 517 > is a SUBSHELL
log.89[0-517].1.0[0-517] np: 1  1750351101.474838  1750351101.474876  (f:2 main.gg)  (s:2 444.517):  < 'gg 1' > is a FUNCTION (C)
1
log.89[0-517].1.1[0-517] np: 1  1750351101.475260  1750351101.475309  (f:2 main.gg)  (s:2 444.517):  < 'echo "$*"' > is a NORMAL COMMAND
log.89[0-517].1.3.0[0-517] np: 1  1750351101.476079  1750351101.476116  (f:3 main.gg.ff)  (s:2 444.517):  < 'ff "$@"' > is a FUNCTION (C)
1
log.89[0-517].1.3.1[0-517] np: 1  1750351101.476474  1750351101.476525  (f:3 main.gg.ff)  (s:2 444.517):  < 'echo "${*}"' > is a NORMAL COMMAND
bye
log.89[0-517].1.3.2[0-517] np: 1  1750351101.476896  1750351101.476953  (f:3 main.gg.ff)  (s:2 444.517):  < 'echo "${*}"' > is a NORMAL COMMAND
log.89[0-517].1.3[0-517] np: 1  1750351101.475666  1750351101.478423  (f:2 main.gg)  (s:2 444.517):  < 'ff "$@"' > is a FUNCTION (P)
bye
log.89[0-517].1.4[0-517] np: 1  1750351101.478650  1750351101.478683  (f:2 main.gg)  (s:2 444.517):  < 'echo "${*}"' > is a NORMAL COMMAND
log.89[0-517].1[0-517] np: 1  1750351101.474437  1750351101.479856  (f:0 main)  (s:2 444.517):  < 'gg 1' > is a FUNCTION (P)
log.89[0-517].2[0-517] np: 1  1750351101.480140  1750351101.480179  (f:0 main)  (s:2 444.517):  < 'exit' > is a NORMAL COMMAND
return
log.89[0-518] np: 1    1750351101.487433  (f:0 main)  (s:2 444):  < pid: 518 > is a SUBSHELL
log.89[0-518].1.0[0-518] np: 1  1750351101.488124  1750351101.488149  (f:2 main.gg)  (s:2 444.518):  < 'gg 1' > is a FUNCTION (C)
1
log.89[0-518].1.1[0-518] np: 1  1750351101.488380  1750351101.488413  (f:2 main.gg)  (s:2 444.518):  < 'echo "$*"' > is a NORMAL COMMAND
log.89[0-518].1.3.0[0-518] np: 1  1750351101.488964  1750351101.488988  (f:3 main.gg.ff)  (s:2 444.518):  < 'ff "$@"' > is a FUNCTION (C)
1
log.89[0-518].1.3.1[0-518] np: 1  1750351101.489229  1750351101.489274  (f:3 main.gg.ff)  (s:2 444.518):  < 'echo "${*}"' > is a NORMAL COMMAND
return
log.89[0-518].1.3.2[0-518] np: 1  1750351101.489510  1750351101.489552  (f:3 main.gg.ff)  (s:2 444.518):  < 'echo "${*}"' > is a NORMAL COMMAND
log.89[0-518].1.3[0-518] np: 1  1750351101.488635  1750351101.490649  (f:2 main.gg)  (s:2 444.518):  < 'ff "$@"' > is a FUNCTION (P)
return
log.89[0-518].1.4[0-518] np: 1  1750351101.490879  1750351101.490934  (f:2 main.gg)  (s:2 444.518):  < 'echo "${*}"' > is a NORMAL COMMAND
log.89[0-518].1[0-518] np: 1  1750351101.487833  1750351101.492076  (f:0 main)  (s:2 444.518):  < 'gg 1' > is a FUNCTION (P)
log.89[0-518].2[0-518] np: 1  1750351101.492319  1750351101.492348  (f:0 main)  (s:2 444.518):  < 'exit' > is a NORMAL COMMAND
log.89[0-519] np: 1    1750351101.497426  (f:0 main)  (s:2 444):  < pid: 519 > is a SUBSHELL
log.89[0-519].0[0-519] np: 1  1750351101.497760  1750351101.497792  (f:0 main)  (s:2 444.519):  < 'exit' > is a NORMAL COMMAND
log.89[0-520] np: 1    1750351101.501982  (f:0 main)  (s:2 444):  < pid: 520 > is a SUBSHELL
log.89[0-520].0[0-520] np: 1  1750351101.502370  1750351101.502403  (f:0 main)  (s:2 444.520):  < 'exit' > is a NORMAL COMMAND
log.89[0-444] np: 1  1750351101.465204  1750351101.502944  (f:0 main)  (s:1 444):  < 'read x' > is a NORMAL COMMAND

EOF

#############################################################################
(
set -T
set -m

: &

read -r _ _ _ _ timep_PARENT_PGID _ _ timep_PARENT_TPID _ </proc/${BASHPID}/stat
timep_CHILD_PGID="$timep_PARENT_PGID"
timep_CHILD_TPID="$timep_PARENT_TPID"

timep_BASHPID_PREV="$BASHPID"
timep_BG_PID_PREV="$!"
timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
timep_SUBSHELL_BASHPID_CUR=''
timep_NEXEC_0=''
timep_NEXEC_A=(0)
timep_NPIDWRAP=0

timep_SIMPLEFORK_NEXT_FLAG=false
timep_SIMPLEFORK_CUR_FLAG=false
timep_SKIP_DEBUG_FLAG=false
timep_NO_PRINT_FLAG=false
timep_IS_FUNC_FLAG_1=false

timep_BASH_COMMAND_PREV=()
timep_NPIPE=()
timep_STARTTIME=()

timep_FNEST=("${#FUNCNAME[@]}")
timep_FNEST_CUR="${#FUNCNAME[@]}"

timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]=''
timep_NPIPE[${timep_FNEST_CUR}]='0'
timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap "${trapStr}"':' EXIT ;;
            RETURN)  builtin trap "${trapStr}"'timep_SKIP_DEBUG_FLAG=true
unset "timep_FNEST[-1]" "timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]" "timep_NPIPE[${timep_FNEST_CUR}]" "timep_STARTTIME[${timep_FNEST_CUR}]" "timep_NEXEC_A[-1]"
timep_NEXEC_0="${timep_NEXEC_0%.*}"
timep_FNEST_CUR="${timep_FNEST[-1]}"
timep_SKIP_DEBUG_FLAG=false' RETURN ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
}

export -f trap

builtin trap ':' EXIT 
builtin trap 'timep_SKIP_DEBUG_FLAG=true
unset "timep_FNEST[-1]" "timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]" "timep_NPIPE[${timep_FNEST_CUR}]" "timep_STARTTIME[${timep_FNEST_CUR}]" "timep_NEXEC_A[-1]"
timep_NEXEC_0="${timep_NEXEC_0%.*}"
timep_FNEST_CUR="${timep_FNEST[-1]}"
timep_SKIP_DEBUG_FLAG=false' RETURN

builtin trap 'timep_NPIPE0=${#PIPESTATUS[@]}
timep_ENDTIME0="${EPOCHREALTIME}"
[[ "${BASH_COMMAND}" == trap* ]] && {
  timep_SKIP_DEBUG_FLAG=true
  (( timep_FNEST_CUR == ${#FUNCNAME[@]} )) && {
    timep_FNEST_CUR=${#FUNCNAME[@]}
    timep_FNEST+=("${#FUNCNAME[@]}")
    timep_BASH_COMMAND_PREV+=('')
    timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
    timep_NEXEC_A+=(0)    
  }
}
${timep_SKIP_DEBUG_FLAG} || {
timep_NPIPE[${timep_FNEST_CUR}]=${timep_NPIPE0}
timep_ENDTIME=${timep_ENDTIME0}
timep_IS_BG_FLAG=false
timep_IS_SUBSHELL_FLAG=false
timep_IS_FUNC_FLAG=false
timep_CMD_TYPE='"''"'
if ${timep_SIMPLEFORK_NEXT_FLAG}; then
  timep_SIMPLEFORK_NEXT_FLAG=false
  timep_SIMPLEFORK_CUR_FLAG=true
else
  timep_SIMPLEFORK_CUR_FLAG=false
fi
if (( timep_BASH_SUBSHELL_PREV == BASH_SUBSHELL )); then
  if (( timep_BG_PID_PREV == $! )); then
    (( timep_FNEST_CUR >= ${#FUNCNAME[@]} )) || {
      timep_NO_PRINT_FLAG=true
      timep_IS_FUNC_FLAG=true
      timep_FNEST+=("${#FUNCNAME[@]}")
    }
  else
    timep_IS_BG_FLAG=true
  fi
else
  timep_IS_SUBSHELL_FLAG=true
  (( BASHPID < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
  timep_SUBSHELL_BASHPID_CUR="$BASHPID" 
  builtin trap '"'"':'"'"' EXIT 
  read -r _ _ _ _ timep_CHILD_PGID _ _ timep_CHILD_TPID _ </proc/${BASHPID}/stat
  (( timep_CHILD_PGID == timep_PARENT_TPID )) || (( timep_CHILD_PGID == timep_CHILD_TPID )) || {  (( timep_CHILD_PGID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )); } || timep_IS_BG_FLAG=true
fi
if ${timep_IS_SUBSHELL_FLAG} && ${timep_IS_BG_FLAG}; then
  (( timep_CHILD_PGID == BASHPID )) && (( timep_CHILD_TPID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )) && timep_SIMPLEFORK_NEXT_FLAG=true
  timep_CMD_TYPE="BACKGROUND FORK"
elif ${timep_IS_SUBSHELL_FLAG}; then
  timep_CMD_TYPE="SUBSHELL"
elif [[ "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]}" == " (F) "* ]]; then
  timep_CMD_TYPE="FUNCTION (P)"
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]# (F) }"
elif ${timep_IS_BG_FLAG}; then
  timep_CMD_TYPE="SIMPLE FORK"
elif ${timep_IS_FUNC_FLAG_1}; then
  timep_CMD_TYPE="FUNCTION (C)"
  timep_IS_FUNC_FLAG_1=false
else
  timep_CMD_TYPE="NORMAL COMMAND"
fi
if ${timep_IS_SUBSHELL_FLAG}; then
  ${timep_NO_PRINT_FLAG} || printf '"'"'[log%s.%s_%s-%s] np: %s  %s  %s  (%s.%s)  (%s.%s):  < pid: %s ( <-- %s ) > is a %s\n'"'"' "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_NPIDWRAP}" "${BASHPID}" "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_STARTTIME[${timep_FNEST_CUR}]}" "${timep_ENDTIME}" "${timep_FNEST_CUR}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "$BASHPID" "$timep_BASHPID_PREV" "$timep_CMD_TYPE" >&${timep_FD}
  timep_NEXEC_0+=".${timep_NEXEC_A[-1]}_${timep_NPIDWRAP}-${BASHPID}"
  timep_NEXEC_A+=(0)
  timep_PARENT_PGID="$timep_CHILD_PGID"
  timep_PARENT_TPID="$timep_CHILD_TPID"
  timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
elif [[ ${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]} ]]; then
  ${timep_SIMPLEFORK_CUR_FLAG} && (( BASHPID < $! )) && timep_CMD_TYPE="SIMPLE FORK *"
  ${timep_NO_PRINT_FLAG} || printf '"'"'[log%s.%s] np: %s  %s  %s  (%s.%s)  (%s.%s):  < %s > is a %s\n'"'"' "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_STARTTIME[${timep_FNEST_CUR}]}" "${timep_ENDTIME}" "${timep_FNEST_CUR}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]@Q}" "$timep_CMD_TYPE"  >&${timep_FD}
  (( timep_NEXEC_A[-1]++ ))
fi 
if ${timep_IS_FUNC_FLAG}; then
  timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
  timep_NEXEC_A+=(0)    
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]=" (F) ${BASH_COMMAND}"
  timep_NPIPE[${#FUNCNAME[@]}]="${timep_NPIPE[${timep_FNEST_CUR}]}"
  timep_FNEST_CUR="${#FUNCNAME[@]}"
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${BASH_COMMAND}"
  timep_NO_PRINT_FLAG=false
  timep_IS_FUNC_FLAG_1=true
else
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="$BASH_COMMAND"
fi
timep_BG_PID_PREV="$!"
timep_BASHPID_PREV="$BASHPID"
timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"
}' DEBUG

{ echo ; } &
{ ( echo A & ); echo B; } &

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &

( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

trap 'echo got USR1; sleep .01' USR1
kill -USR1 $BASHPID
echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done

(
    trap 'echo bye' EXIT
    exit
)

(
    trap 'echo bye' RETURN EXIT
    gg 1
    exit
)

(
    trap 'echo exit' EXIT
    trap 'echo return' RETURN
    gg 1
    exit
)


(
    trap '' RETURN EXIT
    exit
)


(
    trap - EXIT
    exit
)
    
builtin trap - DEBUG EXIT RETURN

) {timep_FD}>&2


:<<'EOF'
0
[log.0_0-2598] np: 1  1750341735.666648  1750341735.667119  (0.main)  (2598.2):  < pid: 2598 ( <-- 2596 ) > is a BACKGROUND FORK

[log.0] np: 1  1750341735.667422  1750341735.667462  (0.main)  (2596.1):  < 'echo 0' > is a NORMAL COMMAND
[log.0_0-2598.0] np: 1  1750341735.667556  1750341735.667604  (0.main)  (2598.2):  < 'echo' > is a NORMAL COMMAND
1
[log.0_0-2600] np: 1  1750341735.666648  1750341735.667432  (0.main)  (2600.3):  < pid: 2600 ( <-- 2596 ) > is a BACKGROUND FORK
A
[log.0_0-2600.0] np: 1  1750341735.667936  1750341735.668182  (0.main)  (2600.3):  < 'echo A' > is a SIMPLE FORK
[log.1_0-2601] np: 1  1750341735.667857  1750341735.668193  (0.main)  (2601.2):  < pid: 2601 ( <-- 2596 ) > is a SUBSHELL
2
[log.1_0-2601.0] np: 1  1750341735.668649  1750341735.668692  (0.main)  (2601.2):  < 'echo 2' > is a NORMAL COMMAND
[log.1] np: 1  1750341735.667857  1750341735.669127  (0.main)  (2596.1):  < 'echo 1' > is a NORMAL COMMAND
[log.0_0-2599] np: 1  1750341735.666648  1750341735.668762  (0.main)  (2599.2):  < pid: 2599 ( <-- 2596 ) > is a BACKGROUND FORK
B
3
[log.0_0-2599.0] np: 1  1750341735.669432  1750341735.669487  (0.main)  (2599.2):  < 'echo B' > is a NORMAL COMMAND
[log.2] np: 1  1750341735.669384  1750341735.669644  (0.main)  (2596.1):  < 'echo 3' > is a SIMPLE FORK
4
[log.3_0-2605] np: 1  1750341735.669967  1750341735.670421  (0.main)  (2605.2):  < pid: 2605 ( <-- 2596 ) > is a BACKGROUND FORK
5
[log.3_0-2606] np: 1  1750341735.669967  1750341735.670537  (0.main)  (2606.2):  < pid: 2606 ( <-- 2596 ) > is a SUBSHELL
[log.3_0-2605.0] np: 1  1750341735.670805  1750341735.670848  (0.main)  (2605.2):  < 'echo 5' > is a NORMAL COMMAND
6
[log.3_0-2606.0] np: 1  1750341735.671005  1750341735.671230  (0.main)  (2606.2):  < 'echo 6' > is a SIMPLE FORK
[log.3_0-2608] np: 1  1750341735.669967  1750341735.671977  (0.main)  (2608.2):  < pid: 2608 ( <-- 2596 ) > is a BACKGROUND FORK
7
[log.3_0-2609] np: 1  1750341735.669967  1750341735.672062  (0.main)  (2609.2):  < pid: 2609 ( <-- 2596 ) > is a SUBSHELL
8
[log.3_0-2608.0] np: 1  1750341735.672353  1750341735.672392  (0.main)  (2608.2):  < 'echo 7' > is a NORMAL COMMAND
[log.3_0-2609.0] np: 1  1750341735.672485  1750341735.672543  (0.main)  (2609.2):  < 'echo 8' > is a NORMAL COMMAND
[log.3_0-2611] np: 1  1750341735.669967  1750341735.673311  (0.main)  (2611.2):  < pid: 2611 ( <-- 2596 ) > is a BACKGROUND FORK
9.1
[log.3_0-2610] np: 1  1750341735.669967  1750341735.673277  (0.main)  (2610.2):  < pid: 2610 ( <-- 2596 ) > is a BACKGROUND FORK
[log.3_0-2612] np: 1  1750341735.669967  1750341735.673426  (0.main)  (2612.2):  < pid: 2612 ( <-- 2596 ) > is a BACKGROUND FORK
[log.3_0-2611.0] np: 1  1750341735.673688  1750341735.673734  (0.main)  (2611.2):  < 'echo 9.1' > is a NORMAL COMMAND
[log.3_0-2613] np: 1  1750341735.669967  1750341735.673609  (0.main)  (2613.2):  < pid: 2613 ( <-- 2596 ) > is a BACKGROUND FORK
9.1b
[log.3_0-2614] np: 1  1750341735.669967  1750341735.673716  (0.main)  (2614.2):  < pid: 2614 ( <-- 2596 ) > is a BACKGROUND FORK
[log.3] np: 1  1750341735.669967  1750341735.673914  (0.main)  (2596.1):  < 'echo 4' > is a SIMPLE FORK
11
[log.3_0-2615] np: 1  1750341735.669967  1750341735.673886  (0.main)  (2615.2):  < pid: 2615 ( <-- 2596 ) > is a BACKGROUND FORK
9.999
[log.3_0-2610.0] np: 1  1750341735.673760  1750341735.674064  (0.main)  (2610.2):  < 'echo 9' > is a SIMPLE FORK *
[log.3_0-2616] np: 1  1750341735.669967  1750341735.673974  (0.main)  (2616.2):  < pid: 2616 ( <-- 2596 ) > is a BACKGROUND FORK
[log.3_0-2613.0] np: 1  1750341735.674136  1750341735.674181  (0.main)  (2613.2):  < 'echo 9.1b' > is a NORMAL COMMAND
[log.3_0-2612.0] np: 1  1750341735.673976  1750341735.674247  (0.main)  (2612.2):  < 'echo 9.1a' > is a SIMPLE FORK *
9.1c
9.2a
[log.3_0-2611.1] np: 1  1750341735.674113  1750341735.674387  (0.main)  (2611.2):  < 'echo 9.2' > is a SIMPLE FORK
[log.4] np: 1  1750341735.674355  1750341735.674399  (0.main)  (2596.1):  < 'echo 11' > is a NORMAL COMMAND
9
[log.3_0-2612.1] np: 1  1750341735.674661  1750341735.674709  (0.main)  (2612.2):  < 'echo 9.2a' > is a NORMAL COMMAND
9.2
10
[log.3_0-2616.0] np: 1  1750341735.674528  1750341735.674786  (0.main)  (2616.2):  < 'echo 10' > is a SIMPLE FORK *
[log.3_0-2614.0] np: 1  1750341735.674228  1750341735.674490  (0.main)  (2614.2):  < 'echo 9.1c' > is a SIMPLE FORK *
9.2c
[log.3_0-2613.1] np: 1  1750341735.674594  1750341735.674891  (0.main)  (2613.2):  < 'echo 9.2b' > is a SIMPLE FORK
[log.3_0-2615.0_0-2621] np: 1  1750341735.674416  1750341735.674824  (0.main)  (2621.3):  < pid: 2621 ( <-- 2615 ) > is a SUBSHELL
12
9.1a
9.2b
[log.3_0-2614.1] np: 1  1750341735.675217  1750341735.675262  (0.main)  (2614.2):  < 'echo 9.2c' > is a NORMAL COMMAND
9.3
[log.3_0-2615.0_0-2621.0] np: 1  1750341735.675304  1750341735.675581  (0.main)  (2621.3):  < 'echo 9.3' > is a SIMPLE FORK
9.4
[log.5_0-2626] np: 1  1750341735.674815  1750341735.675587  (0.main)  (2626.2):  < pid: 2626 ( <-- 2596 ) > is a SUBSHELL
[log.5_0-2625] np: 1  1750341735.674815  1750341735.675620  (0.main)  (2625.2):  < pid: 2625 ( <-- 2596 ) > is a BACKGROUND FORK
14
13
[log.3_0-2615.0_0-2621.1] np: 1  1750341735.675966  1750341735.676006  (0.main)  (2621.3):  < 'echo 9.4' > is a NORMAL COMMAND
[log.5_0-2626.0] np: 1  1750341735.676108  1750341735.676167  (0.main)  (2626.2):  < 'echo 14' > is a NORMAL COMMAND
[log.5_0-2625.0] np: 1  1750341735.676158  1750341735.676214  (0.main)  (2625.2):  < 'echo 13' > is a NORMAL COMMAND
[log.3_0-2615.0] np: 1  1750341735.674416  1750341735.676452  (0.main)  (2615.2):  < 'echo 9.999' > is a NORMAL COMMAND
9.5
[log.5] np: 1  1750341735.674815  1750341735.676855  (0.main)  (2596.1):  < 'echo 12' > is a SIMPLE FORK
[log.3_0-2615.1] np: 1  1750341735.676875  1750341735.676918  (0.main)  (2615.2):  < 'echo 9.5' > is a NORMAL COMMAND
[log.7.0] np: 1  1750341735.677405  1750341735.677427  (2.ff)  (2596.1):  < 'ff 15' > is a FUNCTION (C)
15
[log.7.1] np: 1  1750341735.677676  1750341735.677710  (2.ff)  (2596.1):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.7] np: 1  1750341735.677108  1750341735.678641  (0.main)  (2596.1):  < 'ff 15' > is a FUNCTION (P)
[log.9.0] np: 1  1750341735.679113  1750341735.679134  (2.gg)  (2596.1):  < 'gg 16' > is a FUNCTION (C)
16
[log.9.1] np: 1  1750341735.679365  1750341735.679402  (2.gg)  (2596.1):  < 'echo "$*"' > is a NORMAL COMMAND
[log.9.3.0] np: 1  1750341735.679880  1750341735.679901  (3.ff)  (2596.1):  < 'ff "$@"' > is a FUNCTION (C)
16
[log.9.3.1] np: 1  1750341735.680121  1750341735.680153  (3.ff)  (2596.1):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.9.3] np: 1  1750341735.679650  1750341735.681081  (2.gg)  (2596.1):  < 'ff "$@"' > is a FUNCTION (P)
[log.9_0-2628] np: 1  1750341735.678869  1750341735.682256  (0.main)  (2628.2):  < pid: 2628 ( <-- 2596 ) > is a BACKGROUND FORK
a
[log.9_0-2631] np: 1  1750341735.678869  1750341735.682553  (0.main)  (2631.3):  < pid: 2631 ( <-- 2596 ) > is a BACKGROUND FORK
b
[log.9_0-2630] np: 1  1750341735.678869  1750341735.682650  (0.main)  (2630.2):  < pid: 2630 ( <-- 2596 ) > is a SUBSHELL
[log.9_0-2628.0] np: 1  1750341735.682649  1750341735.682883  (0.main)  (2628.2):  < 'echo a' > is a SIMPLE FORK
[log.9_0-2631.0] np: 1  1750341735.682947  1750341735.682985  (0.main)  (2631.3):  < 'echo b' > is a NORMAL COMMAND
A2
[log.9_0-2633] np: 1  1750341735.678869  1750341735.682892  (0.main)  (2633.4):  < pid: 2633 ( <-- 2596 ) > is a SUBSHELL
[log.9_0-2630.0] np: 1  1750341735.683025  1750341735.683262  (0.main)  (2630.2):  < 'echo A2' > is a SIMPLE FORK
A5
A1
[log.9_0-2630.1] np: 1  1750341735.683629  1750341735.683688  (0.main)  (2630.2):  < 'echo A1' > is a NORMAL COMMAND
[log.9_0-2633.0] np: 1  1750341735.683344  1750341735.683607  (0.main)  (2633.4):  < 'echo A5' > is a SIMPLE FORK
[log.9] np: 1  1750341735.678869  1750341735.684148  (0.main)  (2596.1):  < 'gg 16' > is a FUNCTION (P)
[log.9_0-2632] np: 1  1750341735.678869  1750341735.684342  (0.main)  (2632.3):  < pid: 2632 ( <-- 2596 ) > is a BACKGROUND FORK
A3
[log.9_0-2637] np: 1  1750341735.678869  1750341735.684389  (0.main)  (2637.4):  < pid: 2637 ( <-- 2596 ) > is a BACKGROUND FORK
A4
[log.9_0-2632.0] np: 1  1750341735.684701  1750341735.684742  (0.main)  (2632.3):  < 'echo A3' > is a NORMAL COMMAND
[log.10] np: 1  1750341735.684526  1750341735.684748  (0.main)  (2596.1):  < $'cat <<EOF\nfoo\nbar\nbaz\nEOF\n' > is a NORMAL COMMAND
[log.9_0-2637.0] np: 1  1750341735.684888  1750341735.684940  (0.main)  (2637.4):  < 'echo A4' > is a NORMAL COMMAND
[log.11] np: 1  1750341735.685061  1750341735.685249  (0.main)  (2596.1):  < 'grep foo' > is a NORMAL COMMAND
[log.12] np: 1  1750341735.685510  1750341735.685706  (0.main)  (2596.1):  < 'sed '\''s/o/O/g'\''' > is a NORMAL COMMAND
1
[log.13] np: 4  1750341735.686019  1750341735.687116  (0.main)  (2596.1):  < 'wc -l' > is a NORMAL COMMAND
[log.14_0-2642] np: 4  1750341735.687371  1750341735.687695  (0.main)  (2642.2):  < pid: 2642 ( <-- 2596 ) > is a SUBSHELL
today is 2025-06-19
[log.14] np: 1  1750341735.687371  1750341735.688888  (0.main)  (2596.1):  < 'echo "today is $(date +%Y-%m-%d)"' > is a NORMAL COMMAND
[log.15_0-2643] np: 1  1750341735.689186  1750341735.689674  (0.main)  (2643.2):  < pid: 2643 ( <-- 2596 ) > is a SUBSHELL
[log.15_0-2644] np: 1  1750341735.689186  1750341735.689739  (0.main)  (2644.3):  < pid: 2644 ( <-- 2596 ) > is a SUBSHELL
[log.15_0-2644.0] np: 1  1750341735.690203  1750341735.690237  (0.main)  (2644.3):  < 'echo nested' > is a NORMAL COMMAND
[log.15_0-2644.1] np: 1  1750341735.690469  1750341735.690522  (0.main)  (2644.3):  < 'echo subshell' > is a NORMAL COMMAND
[log.15_0-2643.0] np: 2  1750341735.690022  1750341735.691167  (0.main)  (2643.2):  < 'grep sub' > is a NORMAL COMMAND
[log.15] np: 1  1750341735.689186  1750341735.691751  (0.main)  (2596.1):  < 'x=$( ( echo nested; echo subshell ) | grep sub)' > is a NORMAL COMMAND
[log.16_0-2646] np: 1  1750341735.692086  1750341735.692421  (0.main)  (2646.2):  < pid: 2646 ( <-- 2596 ) > is a SUBSHELL
[log.16_0-2647] np: 1  1750341735.692086  1750341735.692564  (0.main)  (2647.2):  < pid: 2647 ( <-- 2596 ) > is a SUBSHELL
1,22c1,5
< bin
< boot
< dev
< etc
< home
< lib
< lib32
< lib64
< lib.usr-is-merged
< media
< mnt
< opt
< proc
< root
< run
< sbin
< script
< srv
< sys
< tmp
< usr
< var
---
> 3LAOQYG6P8PN3
> ccGTYCpb.s
> hsperfdata_runner83
> modules.timestamp
> TemporaryDirectory.yJwoVY
[log.16] np: 1  1750341735.692086  1750341735.694119  (0.main)  (2596.1):  < 'diff <(ls /) <(ls /tmp)' > is a SIMPLE FORK
[log.17_0-2649] np: 1  1750341735.694399  1750341735.694721  (0.main)  (2649.2):  < pid: 2649 ( <-- 2596 ) > is a SUBSHELL
[log.17] np: 1  1750341735.694399  1750341735.695848  (0.main)  (2596.1):  < 'grep pattern <(sed '\''s/^/>>/'\'' > /dev/null)' > is a SIMPLE FORK
[log.17_0-2651] np: 1  1750341735.694399  1750341735.695896  (0.main)  (2651.2):  < pid: 2651 ( <-- 2596 ) > is a BACKGROUND FORK
[log.17_0-2651.0] np: 1  1750341735.696244  1750341735.696273  (0.main)  (2651.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17_0-2651.1] np: 1  1750341735.696527  1750341735.696567  (0.main)  (2651.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.18] np: 1  1750341735.696176  1750341735.696590  (0.main)  (2596.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 1
[log.19] np: 1  1750341735.696898  1750341735.696932  (0.main)  (2596.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.17_0-2651.2] np: 1  1750341735.696840  1750341735.707803  (0.main)  (2651.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.17_0-2651.3] np: 1  1750341735.708118  1750341735.708149  (0.main)  (2651.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17_0-2651.4] np: 1  1750341735.708471  1750341735.708520  (0.main)  (2651.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.20] np: 1  1750341735.697201  1750341735.708561  (0.main)  (2596.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 2
[log.21] np: 1  1750341735.708863  1750341735.708900  (0.main)  (2596.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.17_0-2651.5] np: 1  1750341735.708774  1750341735.719654  (0.main)  (2651.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.17_0-2651.6] np: 1  1750341735.720160  1750341735.720204  (0.main)  (2651.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17_0-2651.7] np: 1  1750341735.720537  1750341735.720579  (0.main)  (2651.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.22] np: 1  1750341735.709172  1750341735.720607  (0.main)  (2596.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 3
[log.23] np: 1  1750341735.721099  1750341735.721151  (0.main)  (2596.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.17_0-2651.8] np: 1  1750341735.721061  1750341735.732140  (0.main)  (2651.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.24] np: 1  1750341735.721660  1750341735.732881  (0.main)  (2596.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
[log.25] np: 1  1750341735.733390  1750341735.733440  (0.main)  (2596.1):  < 'let "x = 5 + 6"' > is a NORMAL COMMAND
[log.26] np: 1  1750341735.733928  1750341735.733960  (0.main)  (2596.1):  < 'arr=(one two three)' > is a NORMAL COMMAND
one two three
[log.27] np: 1  1750341735.734230  1750341735.734267  (0.main)  (2596.1):  < 'echo ${arr[@]}' > is a NORMAL COMMAND
[log.28] np: 1  1750341735.734601  1750341735.734629  (0.main)  (2596.1):  < '((i=0))' > is a NORMAL COMMAND
[log.29] np: 1  1750341735.734883  1750341735.734910  (0.main)  (2596.1):  < '((i<3))' > is a NORMAL COMMAND
0
[log.30] np: 1  1750341735.735182  1750341735.735229  (0.main)  (2596.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.31] np: 1  1750341735.735622  1750341735.735664  (0.main)  (2596.1):  < '((i++))' > is a NORMAL COMMAND
[log.32] np: 1  1750341735.736065  1750341735.736106  (0.main)  (2596.1):  < '((i<3))' > is a NORMAL COMMAND
1
[log.33] np: 1  1750341735.736387  1750341735.736429  (0.main)  (2596.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.34] np: 1  1750341735.736878  1750341735.736920  (0.main)  (2596.1):  < '((i++))' > is a NORMAL COMMAND
[log.35] np: 1  1750341735.737221  1750341735.737247  (0.main)  (2596.1):  < '((i<3))' > is a NORMAL COMMAND
2
[log.36] np: 1  1750341735.737512  1750341735.737550  (0.main)  (2596.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.37] np: 1  1750341735.737861  1750341735.737886  (0.main)  (2596.1):  < '((i++))' > is a NORMAL COMMAND
[log.38] np: 1  1750341735.738130  1750341735.738175  (0.main)  (2596.1):  < '((i<3))' > is a NORMAL COMMAND
[log.39] np: 1  1750341735.738431  1750341735.738456  (0.main)  (2596.1):  < 'cmd="echo inside-eval"' > is a NORMAL COMMAND
[log.40] np: 1  1750341735.738747  1750341735.738793  (0.main)  (2596.1):  < 'eval "$cmd"' > is a NORMAL COMMAND
inside-eval
[log.41] np: 1  1750341735.739054  1750341735.739088  (0.main)  (2596.1):  < 'echo inside-eval' > is a NORMAL COMMAND
[log.42] np: 1  1750341735.739342  1750341735.739371  (0.main)  (2596.1):  < 'eval "eval \"$cmd\""' > is a NORMAL COMMAND
[log.43] np: 1  1750341735.739651  1750341735.739679  (0.main)  (2596.1):  < 'eval "echo inside-eval"' > is a NORMAL COMMAND
inside-eval
[log.44] np: 1  1750341735.757295  1750341735.757340  (0.main)  (2596.1):  < 'kill -USR1 $BASHPID' > is a NORMAL COMMAND
got USR1
[log.45] np: 1  1750341735.757635  1750341735.757668  (0.main)  (2596.1):  < 'kill -USR1 $BASHPID' > is a NORMAL COMMAND
[log.46] np: 1  1750341735.757937  1750341735.769017  (0.main)  (2596.1):  < 'kill -USR1 $BASHPID' > is a NORMAL COMMAND
after-signal
[log.47] np: 1  1750341735.769358  1750341735.769398  (0.main)  (2596.1):  < 'echo after-signal' > is a NORMAL COMMAND
[log.48] np: 1  1750341735.769690  1750341735.769983  (0.main)  (2596.1):  < 'for i in {1..3}' > is a SIMPLE FORK
[log.48_0-2656] np: 1  1750341735.769690  1750341735.770021  (0.main)  (2656.2):  < pid: 2656 ( <-- 2596 ) > is a SUBSHELL
[log.49] np: 1  1750341735.770319  1750341735.771246  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.50_0-2657] np: 1  1750341735.771628  1750341735.771963  (0.main)  (2657.2):  < pid: 2657 ( <-- 2596 ) > is a SUBSHELL
odd 1
[log.50_0-2657.0] np: 1  1750341735.772401  1750341735.772462  (0.main)  (2657.2):  < 'echo odd "$x"' > is a NORMAL COMMAND
[log.50] np: 1  1750341735.771628  1750341735.772967  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
[log.51] np: 1  1750341735.773460  1750341735.773522  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.52] np: 1  1750341735.773936  1750341735.773974  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 2
[log.53] np: 1  1750341735.774347  1750341735.774379  (0.main)  (2596.1):  < 'echo even "$x"' > is a NORMAL COMMAND
[log.54] np: 1  1750341735.774669  1750341735.774699  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.55_0-2658] np: 1  1750341735.774947  1750341735.775298  (0.main)  (2658.2):  < pid: 2658 ( <-- 2596 ) > is a SUBSHELL
odd 3
[log.55_0-2658.0] np: 1  1750341735.775755  1750341735.775807  (0.main)  (2658.2):  < 'echo odd "$x"' > is a NORMAL COMMAND
[log.55] np: 1  1750341735.774947  1750341735.776266  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
[log.56] np: 1  1750341735.776707  1750341735.776748  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.57] np: 1  1750341735.777147  1750341735.777181  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 4
[log.58] np: 1  1750341735.777589  1750341735.777622  (0.main)  (2596.1):  < 'echo even "$x"' > is a NORMAL COMMAND
[log.59] np: 1  1750341735.777879  1750341735.777908  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.60_0-2659] np: 1  1750341735.778163  1750341735.778508  (0.main)  (2659.2):  < pid: 2659 ( <-- 2596 ) > is a SUBSHELL
odd 5
[log.60_0-2659.0] np: 1  1750341735.778940  1750341735.778982  (0.main)  (2659.2):  < 'echo odd "$x"' > is a NORMAL COMMAND
[log.60] np: 1  1750341735.778163  1750341735.779424  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
[log.61] np: 1  1750341735.779783  1750341735.779821  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.62] np: 1  1750341735.780071  1750341735.780335  (0.main)  (2596.1):  < 'for i in {1..3}' > is a SIMPLE FORK
[log.62_0-2660] np: 1  1750341735.780071  1750341735.780386  (0.main)  (2660.2):  < pid: 2660 ( <-- 2596 ) > is a SUBSHELL
[log.63] np: 1  1750341735.780689  1750341735.781406  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.64_0-2661] np: 1  1750341735.781869  1750341735.782199  (0.main)  (2661.2):  < pid: 2661 ( <-- 2596 ) > is a SUBSHELL
odd 1
[log.64_0-2661.0] np: 1  1750341735.782601  1750341735.782665  (0.main)  (2661.2):  < 'echo odd "$x"' > is a NORMAL COMMAND
[log.64] np: 1  1750341735.781869  1750341735.783201  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
[log.65] np: 1  1750341735.783591  1750341735.783625  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.66] np: 1  1750341735.783882  1750341735.783908  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 2
[log.67] np: 1  1750341735.784199  1750341735.784232  (0.main)  (2596.1):  < 'echo even "$x"' > is a NORMAL COMMAND
[log.68] np: 1  1750341735.784484  1750341735.784532  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.69_0-2662] np: 1  1750341735.784782  1750341735.785115  (0.main)  (2662.2):  < pid: 2662 ( <-- 2596 ) > is a SUBSHELL
odd 3
[log.69_0-2662.0] np: 1  1750341735.785507  1750341735.785567  (0.main)  (2662.2):  < 'echo odd "$x"' > is a NORMAL COMMAND
[log.69] np: 1  1750341735.784782  1750341735.785996  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
[log.70] np: 1  1750341735.786311  1750341735.786343  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.71] np: 1  1750341735.786622  1750341735.786648  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 4
[log.72] np: 1  1750341735.786895  1750341735.786927  (0.main)  (2596.1):  < 'echo even "$x"' > is a NORMAL COMMAND
[log.73] np: 1  1750341735.787179  1750341735.787209  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.74_0-2663] np: 1  1750341735.787470  1750341735.787821  (0.main)  (2663.2):  < pid: 2663 ( <-- 2596 ) > is a SUBSHELL
odd 5
[log.74_0-2663.0] np: 1  1750341735.788196  1750341735.788245  (0.main)  (2663.2):  < 'echo odd "$x"' > is a NORMAL COMMAND
[log.74] np: 1  1750341735.787470  1750341735.788759  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
[log.75] np: 1  1750341735.789251  1750341735.789310  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.76_0-2664] np: 1  1750341735.789779  1750341735.790124  (0.main)  (2664.2):  < pid: 2664 ( <-- 2596 ) > is a SUBSHELL
[log.76] np: 1  1750341735.789779  1750341735.790092  (0.main)  (2596.1):  < 'for i in {1..3}' > is a SIMPLE FORK
[log.77] np: 1  1750341735.790636  1750341735.791285  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.78_0-2665] np: 1  1750341735.791713  1750341735.792045  (0.main)  (2665.2):  < pid: 2665 ( <-- 2596 ) > is a SUBSHELL
odd 1
[log.78_0-2665.0] np: 1  1750341735.792508  1750341735.792557  (0.main)  (2665.2):  < 'echo odd "$x"' > is a NORMAL COMMAND
[log.78] np: 1  1750341735.791713  1750341735.793046  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
[log.79] np: 1  1750341735.793350  1750341735.793383  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.80] np: 1  1750341735.793715  1750341735.793745  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 2
[log.81] np: 1  1750341735.794013  1750341735.794055  (0.main)  (2596.1):  < 'echo even "$x"' > is a NORMAL COMMAND
[log.82] np: 1  1750341735.794321  1750341735.794358  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.83_0-2666] np: 1  1750341735.794644  1750341735.794985  (0.main)  (2666.2):  < pid: 2666 ( <-- 2596 ) > is a SUBSHELL
odd 3
[log.83_0-2666.0] np: 1  1750341735.795311  1750341735.795349  (0.main)  (2666.2):  < 'echo odd "$x"' > is a NORMAL COMMAND
[log.83] np: 1  1750341735.794644  1750341735.795795  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
[log.84] np: 1  1750341735.796127  1750341735.796159  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.85] np: 1  1750341735.796430  1750341735.796457  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
even 4
[log.86] np: 1  1750341735.796753  1750341735.796793  (0.main)  (2596.1):  < 'echo even "$x"' > is a NORMAL COMMAND
[log.87] np: 1  1750341735.797089  1750341735.797120  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND
[log.88_0-2667] np: 1  1750341735.797371  1750341735.797713  (0.main)  (2667.2):  < pid: 2667 ( <-- 2596 ) > is a SUBSHELL
odd 5
[log.88_0-2667.0] np: 1  1750341735.798214  1750341735.798259  (0.main)  (2667.2):  < 'echo odd "$x"' > is a NORMAL COMMAND
[log.88] np: 1  1750341735.797371  1750341735.798702  (0.main)  (2596.1):  < '(( x % 2 == 0 ))' > is a NORMAL COMMAND
[log.89_0-2668] np: 1    1750341735.802451  (0.main)  (2668.2):  < pid: 2668 ( <-- 2596 ) > is a SUBSHELL
[log.89_0-2668.0] np: 1  1750341735.802791  1750341735.802824  (0.main)  (2668.2):  < 'exit' > is a NORMAL COMMAND
bye
[log.89_0-2669] np: 1    1750341735.807550  (0.main)  (2669.2):  < pid: 2669 ( <-- 2596 ) > is a SUBSHELL
[log.89_0-2669.1.0] np: 1  1750341735.808141  1750341735.808185  (2.gg)  (2669.2):  < 'gg 1' > is a FUNCTION (C)
1
[log.89_0-2669.1.1] np: 1  1750341735.808417  1750341735.808457  (2.gg)  (2669.2):  < 'echo "$*"' > is a NORMAL COMMAND
[log.89_0-2669.1.3.0] np: 1  1750341735.808986  1750341735.809009  (3.ff)  (2669.2):  < 'ff "$@"' > is a FUNCTION (C)
1
[log.89_0-2669.1.3.1] np: 1  1750341735.809255  1750341735.809289  (3.ff)  (2669.2):  < 'echo "${*}"' > is a NORMAL COMMAND
bye
[log.89_0-2669.1.3.2] np: 1  1750341735.809514  1750341735.809545  (3.ff)  (2669.2):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.89_0-2669.1.3] np: 1  1750341735.808716  1750341735.810421  (2.gg)  (2669.2):  < 'ff "$@"' > is a FUNCTION (P)
bye
[log.89_0-2669.1.4] np: 1  1750341735.810690  1750341735.810736  (2.gg)  (2669.2):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.89_0-2669.1] np: 1  1750341735.807883  1750341735.811705  (0.main)  (2669.2):  < 'gg 1' > is a FUNCTION (P)
[log.89_0-2669.2] np: 1  1750341735.811927  1750341735.811974  (0.main)  (2669.2):  < 'exit' > is a NORMAL COMMAND
return
[log.89_0-2670] np: 1    1750341735.819479  (0.main)  (2670.2):  < pid: 2670 ( <-- 2596 ) > is a SUBSHELL
[log.89_0-2670.1.0] np: 1  1750341735.820171  1750341735.820194  (2.gg)  (2670.2):  < 'gg 1' > is a FUNCTION (C)
1
[log.89_0-2670.1.1] np: 1  1750341735.820443  1750341735.820481  (2.gg)  (2670.2):  < 'echo "$*"' > is a NORMAL COMMAND
[log.89_0-2670.1.3.0] np: 1  1750341735.821247  1750341735.821279  (3.ff)  (2670.2):  < 'ff "$@"' > is a FUNCTION (C)
1
[log.89_0-2670.1.3.1] np: 1  1750341735.821585  1750341735.821662  (3.ff)  (2670.2):  < 'echo "${*}"' > is a NORMAL COMMAND
return
[log.89_0-2670.1.3.2] np: 1  1750341735.821965  1750341735.822001  (3.ff)  (2670.2):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.89_0-2670.1.3] np: 1  1750341735.820832  1750341735.823153  (2.gg)  (2670.2):  < 'ff "$@"' > is a FUNCTION (P)
return
[log.89_0-2670.1.4] np: 1  1750341735.823384  1750341735.823414  (2.gg)  (2670.2):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.89_0-2670.1] np: 1  1750341735.819900  1750341735.824362  (0.main)  (2670.2):  < 'gg 1' > is a FUNCTION (P)
[log.89_0-2670.2] np: 1  1750341735.824601  1750341735.824637  (0.main)  (2670.2):  < 'exit' > is a NORMAL COMMAND
[log.89_0-2671] np: 1    1750341735.829880  (0.main)  (2671.2):  < pid: 2671 ( <-- 2596 ) > is a SUBSHELL
[log.89_0-2671.0] np: 1  1750341735.830309  1750341735.830360  (0.main)  (2671.2):  < 'exit' > is a NORMAL COMMAND
[log.89_0-2672] np: 1    1750341735.833906  (0.main)  (2672.2):  < pid: 2672 ( <-- 2596 ) > is a SUBSHELL
[log.89_0-2672.0] np: 1  1750341735.834182  1750341735.834213  (0.main)  (2672.2):  < 'exit' > is a NORMAL COMMAND
[log.89] np: 1  1750341735.799030  1750341735.834679  (0.main)  (2596.1):  < 'read x' > is a NORMAL COMMAND

EOF



###################################################################################################
(
set -T
set -m

: &

read -r _ _ _ _ timep_PARENT_PGID _ _ timep_PARENT_TPID _ </proc/${BASHPID}/stat
timep_CHILD_PGID="$timep_PARENT_PGID"
timep_CHILD_TPID="$timep_PARENT_TPID"

timep_BASHPID_PREV="$BASHPID"
timep_BG_PID_PREV="$!"
timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
timep_SUBSHELL_BASHPID_CUR=''
timep_NEXEC_0=''
timep_NEXEC_A=(0)
timep_NPIDWRAP=0

timep_SIMPLEFORK_NEXT_FLAG=false
timep_SIMPLEFORK_CUR_FLAG=false
timep_SKIP_DEBUG_FLAG=false
timep_NO_PRINT_FLAG=false
timep_IS_FUNC_FLAG_1=false

timep_BASH_COMMAND_PREV=()
timep_NPIPE=()
timep_STARTTIME=()

timep_FNEST=("${#FUNCNAME[@]}")
timep_FNEST_CUR="${#FUNCNAME[@]}"

timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]=''
timep_NPIPE[${timep_FNEST_CUR}]='0'
timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap ':' EXIT ;;
            RETURN)  builtin trap  'timep_SKIP_DEBUG_FLAG=true
unset "timep_FNEST[-1]" "timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]" "timep_NPIPE[${timep_FNEST_CUR}]" "timep_STARTTIME[${timep_FNEST_CUR}]" "timep_NEXEC_A[-1]"
timep_NEXEC_0="${timep_NEXEC_0%.*}"
timep_FNEST_CUR="${timep_FNEST[-1]}"
timep_SKIP_DEBUG_FLAG=false' RETURN ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
}

export -f trap

builtin trap ':' EXIT 
builtin trap 'timep_SKIP_DEBUG_FLAG=true
unset "timep_FNEST[-1]" "timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]" "timep_NPIPE[${timep_FNEST_CUR}]" "timep_STARTTIME[${timep_FNEST_CUR}]" "timep_NEXEC_A[-1]"
timep_NEXEC_0="${timep_NEXEC_0%.*}"
timep_FNEST_CUR="${timep_FNEST[-1]}"
timep_SKIP_DEBUG_FLAG=false' RETURN

builtin trap 'timep_NPIPE0=${#PIPESTATUS[@]}
timep_ENDTIME0="${EPOCHREALTIME}"
[[ "${BASH_COMMAND}" == trap* ]] && {
  timep_SKIP_DEBUG_FLAG=true
  (( timep_FNEST_CUR == ${#FUNCNAME[@]} )) && {
    timep_FNEST_CUR=${#FUNCNAME[@]}
    timep_FNEST+=("${#FUNCNAME[@]}")
    timep_BASH_COMMAND_PREV+=('')
    timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
    timep_NEXEC_A+=(0)    
  }
}
${timep_SKIP_DEBUG_FLAG} || {
timep_NPIPE[${timep_FNEST_CUR}]=${timep_NPIPE0}
timep_ENDTIME=${timep_ENDTIME0}
timep_IS_BG_FLAG=false
timep_IS_SUBSHELL_FLAG=false
timep_IS_FUNC_FLAG=false
timep_CMD_TYPE='"''"'
if ${timep_SIMPLEFORK_NEXT_FLAG}; then
  timep_SIMPLEFORK_NEXT_FLAG=false
  timep_SIMPLEFORK_CUR_FLAG=true
else
  timep_SIMPLEFORK_CUR_FLAG=false
fi
if (( timep_BASH_SUBSHELL_PREV == BASH_SUBSHELL )); then
  if (( timep_BG_PID_PREV == $! )); then
    (( timep_FNEST_CUR >= ${#FUNCNAME[@]} )) || {
      timep_NO_PRINT_FLAG=true
      timep_IS_FUNC_FLAG=true
      timep_FNEST+=("${#FUNCNAME[@]}")
    }
  else
    timep_IS_BG_FLAG=true
  fi
else
  timep_IS_SUBSHELL_FLAG=true
  (( BASHPID < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
  timep_SUBSHELL_BASHPID_CUR="$BASHPID" 
  builtin trap '"'"':'"'"' EXIT 
  read -r _ _ _ _ timep_CHILD_PGID _ _ timep_CHILD_TPID _ </proc/${BASHPID}/stat
  (( timep_CHILD_PGID == timep_PARENT_TPID )) || (( timep_CHILD_PGID == timep_CHILD_TPID )) || {  (( timep_CHILD_PGID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )); } || timep_IS_BG_FLAG=true
fi
if ${timep_IS_SUBSHELL_FLAG} && ${timep_IS_BG_FLAG}; then
  (( timep_CHILD_PGID == BASHPID )) && (( timep_CHILD_TPID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )) && timep_SIMPLEFORK_NEXT_FLAG=true
  timep_CMD_TYPE="BACKGROUND FORK"
elif ${timep_IS_SUBSHELL_FLAG}; then
  timep_CMD_TYPE="SUBSHELL"
elif [[ "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]}" == " (F) "* ]]; then
  timep_CMD_TYPE="FUNCTION (P)"
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]# (F) }"
elif ${timep_IS_BG_FLAG}; then
  timep_CMD_TYPE="SIMPLE FORK"
elif ${timep_IS_FUNC_FLAG_1}; then
  timep_CMD_TYPE="FUNCTION (C)"
  timep_IS_FUNC_FLAG_1=false
else
  timep_CMD_TYPE="NORMAL COMMAND"
fi
if ${timep_IS_SUBSHELL_FLAG}; then
  ${timep_NO_PRINT_FLAG} || printf '"'"'[log%s.%s_%s-%s] np: %s  %s  %s  (%s.%s)  (%s.%s):  < pid: %s ( <-- %s ) > is a %s\n'"'"' "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_NPIDWRAP}" "${BASHPID}" "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_STARTTIME[${timep_FNEST_CUR}]}" "${timep_ENDTIME}" "${timep_FNEST_CUR}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "$BASHPID" "$timep_BASHPID_PREV" "$timep_CMD_TYPE" >&${timep_FD}
  timep_NEXEC_0+=".${timep_NEXEC_A[-1]}_${timep_NPIDWRAP}-${BASHPID}"
  timep_NEXEC_A+=(0)
  timep_PARENT_PGID="$timep_CHILD_PGID"
  timep_PARENT_TPID="$timep_CHILD_TPID"
  timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
elif [[ ${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]} ]]; then
  ${timep_SIMPLEFORK_CUR_FLAG} && (( BASHPID < $! )) && timep_CMD_TYPE="SIMPLE FORK *"
  ${timep_NO_PRINT_FLAG} || printf '"'"'[log%s.%s] np: %s  %s  %s  (%s.%s)  (%s.%s):  < %s > is a %s\n'"'"' "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_STARTTIME[${timep_FNEST_CUR}]}" "${timep_ENDTIME}" "${timep_FNEST_CUR}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]@Q}" "$timep_CMD_TYPE"  >&${timep_FD}
  (( timep_NEXEC_A[-1]++ ))
fi 
if ${timep_IS_FUNC_FLAG}; then
  timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
  timep_NEXEC_A+=(0)    
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]=" (F) ${BASH_COMMAND}"
  timep_NPIPE[${#FUNCNAME[@]}]="${timep_NPIPE[${timep_FNEST_CUR}]}"
  timep_FNEST_CUR="${#FUNCNAME[@]}"
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${BASH_COMMAND}"
  timep_NO_PRINT_FLAG=false
  timep_IS_FUNC_FLAG_1=true
else
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="$BASH_COMMAND"
fi
timep_BG_PID_PREV="$!"
timep_BASHPID_PREV="$BASHPID"
timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"
}' DEBUG

{ echo ; } &
{ ( echo A & ); echo B; } &

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &

( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

#trap 'echo got USR1; sleep .01' USR1
#kill -USR1 $$
#echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done
    
builtin trap - DEBUG EXIT RETURN

) {timep_FD}>&2










###########################################################################

(

set -T
set -m

: &

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
subshell_pid=''
nexec0=''
nexecA=(0)
npidwrap=0

next_is_simple_fork_flag=false
this_is_simple_fork_flag=false
skip_debug=false
no_print_flag=false
is_func1=false

last_command=()
npipe=()
starttime=()

fnest=(${#FUNCNAME[@]})
fnest_cur=${#FUNCNAME[@]}

last_command[${fnest_cur}]=''
npipe[${fnest_cur}]='0'
starttime[${fnest_cur}]="${EPOCHREALTIME}"

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap ':' EXIT ;;
            RETURN)  builtin trap  'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]" "npipe[${fnest_cur}]" "starttime[${fnest_cur}]" "nexecA[-1]"
nexec0="${nexec0%.*}"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
}

export -f trap

builtin trap ':' EXIT 
builtin trap 'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]" "npipe[${fnest_cur}]" "starttime[${fnest_cur}]" "nexecA[-1]"
nexec0="${nexec0%.*}"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN

builtin trap 'npipe0=${#PIPESTATUS[@]}
endtime0="${EPOCHREALTIME}"
[[ "${BASH_COMMAND}" == trap* ]] && {
  skip_debug=true
  (( fnest_cur == ${#FUNCNAME[@]} )) && {
    fnest_cur=${#FUNCNAME[@]}
    fnest+=("${#FUNCNAME[@]}")
    last_command+=('')
    nexec0+=".${nexecA[-1]}"
    nexecA+=(0)    
  }
}
${skip_debug} || {
npipe[${fnest_cur}]=${npipe0}
endtime=${endtime0}
is_bg=false
is_subshell=false
is_func=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  if (( last_bg_pid == $! )); then
    (( fnest_cur >= ${#FUNCNAME[@]} )) || {
      no_print_flag=true
      is_func=true
      fnest+=("${#FUNCNAME[@]}")
    }
  else
    is_bg=true
  fi
else
  is_subshell=true
  (( BASHPID < last_pid )) && (( npidwrap++ ))
  subshell_pid=$BASHPID 
  builtin trap '"'"':'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == parent_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
  cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif [[ "${last_command[${fnest_cur}]}" == " (F) "* ]]; then
  cmd_type="FUNCTION (P)"
  last_command[${fnest_cur}]="${last_command[${fnest_cur}]# (F) }"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
elif ${is_func1}; then
  cmd_type="FUNCTION (C)"
  is_func1=false
else
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  ${no_print_flag} || printf '"'"'[log%s.%s_%s-%s] np: %s  %s  %s  (%s.%s)  (%s.%s):  < pid: %s ( <-- %s ) > is a %s\n'"'"' "${nexec0}" "${nexecA[-1]}" "${npidwrap}" "${BASHPID}" "${npipe[${fnest_cur}]}" "${starttime[${fnest_cur}]}" "${endtime}" "${fnest_cur}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "$BASHPID" "$last_pid" "$cmd_type" >&${fd}
  nexec0+=".${nexecA[-1]}_${npidwrap}-${BASHPID}"
  nexecA+=(0)
  parent_pgid="$child_pgid"
  parent_tpid="$child_tpid"
  last_subshell="$BASH_SUBSHELL"
elif [[ ${last_command[${fnest_cur}]} ]]; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  ${no_print_flag} || printf '"'"'[log%s.%s] np: %s  %s  %s  (%s.%s)  (%s.%s):  < %s > is a %s\n'"'"' "${nexec0}" "${nexecA[-1]}" "${npipe[${fnest_cur}]}" "${starttime[${fnest_cur}]}" "${endtime}" "${fnest_cur}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "${last_command[${fnest_cur}]@Q}" "$cmd_type"  >&${fd}
  (( nexecA[-1]++ ))
fi 
if ${is_func}; then
  nexec0+=".${nexecA[-1]}"
  nexecA+=(0)    
  last_command[${fnest_cur}]=" (F) ${BASH_COMMAND}"
  npipe[${#FUNCNAME[@]}]="${npipe[${fnest_cur}]}"
  fnest_cur="${#FUNCNAME[@]}"
  last_command[${fnest_cur}]="${BASH_COMMAND}"
  no_print_flag=false
  is_func1=true
else
  last_command[${fnest_cur}]="$BASH_COMMAND"
fi
last_bg_pid="$!"
last_pid="$BASHPID"
starttime[${fnest_cur}]="${EPOCHREALTIME}"
}' DEBUG

{ echo ; } &
{ ( echo A & ); echo B; } &

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &

( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

trap 'echo got USR1; sleep .01' USR1
kill -USR1 $$
echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done
    
builtin trap - DEBUG EXIT RETURN

) {fd}>&2

# raw

:<<'EOF'

[log.0_0-1232] np: 1  1750267869.903638  1750267869.904167  (0.main)  (1232.2):  < pid: 1232 ( <-- 1230 ) > is a BACKGROUND FORK
0

[log.0_0-1234] np: 1  1750267869.903638  1750267869.904539  (0.main)  (1234.3):  < pid: 1234 ( <-- 1230 ) > is a BACKGROUND FORK
[log.0_0-1232.0] np: 1  1750267869.904665  1750267869.904714  (0.main)  (1232.2):  < 'echo' > is a NORMAL COMMAND
[log.0] np: 1  1750267869.904625  1750267869.904671  (0.main)  (1230.1):  < 'echo 0' > is a NORMAL COMMAND
1
A
[log.0_0-1234.0] np: 1  1750267869.905015  1750267869.905307  (0.main)  (1234.3):  < 'echo A' > is a SIMPLE FORK
[log.1_0-1236] np: 1  1750267869.905098  1750267869.905464  (0.main)  (1236.2):  < pid: 1236 ( <-- 1230 ) > is a SUBSHELL
2
[log.1_0-1236.0] np: 1  1750267869.905834  1750267869.905887  (0.main)  (1236.2):  < 'echo 2' > is a NORMAL COMMAND
[log.0_0-1233] np: 1  1750267869.903638  1750267869.905887  (0.main)  (1233.2):  < pid: 1233 ( <-- 1230 ) > is a BACKGROUND FORK
B
[log.0_0-1233.0] np: 1  1750267869.906232  1750267869.906271  (0.main)  (1233.2):  < 'echo B' > is a NORMAL COMMAND
[log.1] np: 1  1750267869.905098  1750267869.906288  (0.main)  (1230.1):  < 'echo 1' > is a NORMAL COMMAND
3
[log.2] np: 1  1750267869.906678  1750267869.906970  (0.main)  (1230.1):  < 'echo 3' > is a SIMPLE FORK
4
[log.3_0-1239] np: 1  1750267869.907324  1750267869.907847  (0.main)  (1239.2):  < pid: 1239 ( <-- 1230 ) > is a BACKGROUND FORK
[log.3_0-1240] np: 1  1750267869.907324  1750267869.907965  (0.main)  (1240.2):  < pid: 1240 ( <-- 1230 ) > is a SUBSHELL
5
[log.3_0-1239.0] np: 1  1750267869.908278  1750267869.908317  (0.main)  (1239.2):  < 'echo 5' > is a NORMAL COMMAND
6
[log.3_0-1240.0] np: 1  1750267869.908314  1750267869.908524  (0.main)  (1240.2):  < 'echo 6' > is a SIMPLE FORK
[log.3_0-1242] np: 1  1750267869.907324  1750267869.909257  (0.main)  (1242.2):  < pid: 1242 ( <-- 1230 ) > is a BACKGROUND FORK
7
[log.3_0-1243] np: 1  1750267869.907324  1750267869.909399  (0.main)  (1243.2):  < pid: 1243 ( <-- 1230 ) > is a SUBSHELL
8
[log.3_0-1242.0] np: 1  1750267869.909575  1750267869.909622  (0.main)  (1242.2):  < 'echo 7' > is a NORMAL COMMAND
[log.3_0-1243.0] np: 1  1750267869.909711  1750267869.909767  (0.main)  (1243.2):  < 'echo 8' > is a NORMAL COMMAND
[log.3_0-1244] np: 1  1750267869.907324  1750267869.910495  (0.main)  (1244.2):  < pid: 1244 ( <-- 1230 ) > is a BACKGROUND FORK
[log.3_0-1245] np: 1  1750267869.907324  1750267869.910567  (0.main)  (1245.2):  < pid: 1245 ( <-- 1230 ) > is a BACKGROUND FORK
9.1
[log.3_0-1246] np: 1  1750267869.907324  1750267869.910742  (0.main)  (1246.2):  < pid: 1246 ( <-- 1230 ) > is a BACKGROUND FORK
[log.3_0-1247] np: 1  1750267869.907324  1750267869.910875  (0.main)  (1247.2):  < pid: 1247 ( <-- 1230 ) > is a BACKGROUND FORK
9
[log.3_0-1248] np: 1  1750267869.907324  1750267869.911046  (0.main)  (1248.2):  < pid: 1248 ( <-- 1230 ) > is a BACKGROUND FORK
9.1a
[log.3] np: 1  1750267869.907324  1750267869.911253  (0.main)  (1230.1):  < 'echo 4' > is a SIMPLE FORK
[log.3_0-1245.0] np: 1  1750267869.911024  1750267869.911067  (0.main)  (1245.2):  < 'echo 9.1' > is a NORMAL COMMAND
[log.3_0-1246.0] np: 1  1750267869.911222  1750267869.911473  (0.main)  (1246.2):  < 'echo 9.1a' > is a SIMPLE FORK *
11
[log.3_0-1248.0] np: 1  1750267869.911537  1750267869.911830  (0.main)  (1248.2):  < 'echo 9.1c' > is a SIMPLE FORK *
9.2a
9.2c
9.2
[log.4] np: 1  1750267869.912134  1750267869.912187  (0.main)  (1230.1):  < 'echo 11' > is a NORMAL COMMAND
[log.3_0-1248.1] np: 1  1750267869.912191  1750267869.912238  (0.main)  (1248.2):  < 'echo 9.2c' > is a NORMAL COMMAND
[log.3_0-1246.1] np: 1  1750267869.912166  1750267869.912225  (0.main)  (1246.2):  < 'echo 9.2a' > is a NORMAL COMMAND
[log.3_0-1251] np: 1  1750267869.907324  1750267869.911370  (0.main)  (1251.2):  < pid: 1251 ( <-- 1230 ) > is a BACKGROUND FORK
12
9.1c
[log.3_0-1245.1] np: 1  1750267869.912133  1750267869.912420  (0.main)  (1245.2):  < 'echo 9.2' > is a SIMPLE FORK
[log.3_0-1244.0] np: 1  1750267869.910890  1750267869.911172  (0.main)  (1244.2):  < 'echo 9' > is a SIMPLE FORK *
9.1b
[log.3_0-1249] np: 1  1750267869.907324  1750267869.911578  (0.main)  (1249.2):  < pid: 1249 ( <-- 1230 ) > is a BACKGROUND FORK
9.999
10
[log.3_0-1251.0] np: 1  1750267869.912957  1750267869.913256  (0.main)  (1251.2):  < 'echo 10' > is a SIMPLE FORK *
[log.3_0-1247.0] np: 1  1750267869.912041  1750267869.913338  (0.main)  (1247.2):  < 'echo 9.1b' > is a NORMAL COMMAND
[log.5_0-1256] np: 1  1750267869.912514  1750267869.913369  (0.main)  (1256.2):  < pid: 1256 ( <-- 1230 ) > is a BACKGROUND FORK
13
9.2b
[log.5_0-1256.0] np: 1  1750267869.914072  1750267869.914193  (0.main)  (1256.2):  < 'echo 13' > is a NORMAL COMMAND
[log.5_0-1257] np: 1  1750267869.912514  1750267869.913392  (0.main)  (1257.2):  < pid: 1257 ( <-- 1230 ) > is a SUBSHELL
14
[log.3_0-1247.1] np: 1  1750267869.913979  1750267869.914354  (0.main)  (1247.2):  < 'echo 9.2b' > is a SIMPLE FORK
[log.3_0-1249.0_0-1259] np: 1  1750267869.913371  1750267869.914310  (0.main)  (1259.3):  < pid: 1259 ( <-- 1249 ) > is a BACKGROUND FORK
[log.5_0-1257.0] np: 1  1750267869.914597  1750267869.914648  (0.main)  (1257.2):  < 'echo 14' > is a NORMAL COMMAND
9.3
[log.5] np: 1  1750267869.912514  1750267869.915241  (0.main)  (1230.1):  < 'echo 12' > is a SIMPLE FORK
[log.3_0-1249.0_0-1259.0] np: 1  1750267869.914825  1750267869.915236  (0.main)  (1259.3):  < 'echo 9.3' > is a SIMPLE FORK
9.4
[log.3_0-1249.0_0-1259.1] np: 1  1750267869.915669  1750267869.915736  (0.main)  (1259.3):  < 'echo 9.4' > is a NORMAL COMMAND
[log.7.0] np: 1  1750267869.915806  1750267869.915840  (2.ff)  (1230.1):  < 'ff 15' > is a FUNCTION (C)
15
[log.7.1] np: 1  1750267869.916177  1750267869.916225  (2.ff)  (1230.1):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.3_0-1249.0] np: 1  1750267869.913371  1750267869.916373  (0.main)  (1249.2):  < 'echo 9.999' > is a NORMAL COMMAND
9.5
[log.3_0-1249.1] np: 1  1750267869.916792  1750267869.916844  (0.main)  (1249.2):  < 'echo 9.5' > is a NORMAL COMMAND
[log.7] np: 1  1750267869.915478  1750267869.917382  (0.main)  (1230.1):  < 'ff 15' > is a FUNCTION (P)
[log.9.0] np: 1  1750267869.917851  1750267869.917872  (2.gg)  (1230.1):  < 'gg 16' > is a FUNCTION (C)
16
[log.9.1] np: 1  1750267869.918065  1750267869.918094  (2.gg)  (1230.1):  < 'echo "$*"' > is a NORMAL COMMAND
[log.9.3.0] np: 1  1750267869.918557  1750267869.918578  (3.ff)  (1230.1):  < 'ff "$@"' > is a FUNCTION (C)
16
[log.9.3.1] np: 1  1750267869.918846  1750267869.918881  (3.ff)  (1230.1):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.9.3] np: 1  1750267869.918331  1750267869.919779  (2.gg)  (1230.1):  < 'ff "$@"' > is a FUNCTION (P)
[log.9_0-1262] np: 1  1750267869.917608  1750267869.921147  (0.main)  (1262.2):  < pid: 1262 ( <-- 1230 ) > is a BACKGROUND FORK
a
[log.9_0-1265] np: 1  1750267869.917608  1750267869.921583  (0.main)  (1265.3):  < pid: 1265 ( <-- 1230 ) > is a BACKGROUND FORK
b
[log.9_0-1262.0] np: 1  1750267869.921580  1750267869.921901  (0.main)  (1262.2):  < 'echo a' > is a SIMPLE FORK
[log.9_0-1265.0] np: 1  1750267869.922064  1750267869.922115  (0.main)  (1265.3):  < 'echo b' > is a NORMAL COMMAND
[log.9_0-1264] np: 1  1750267869.917608  1750267869.922036  (0.main)  (1264.2):  < pid: 1264 ( <-- 1230 ) > is a SUBSHELL
[log.9_0-1268] np: 1  1750267869.917608  1750267869.922082  (0.main)  (1268.4):  < pid: 1268 ( <-- 1230 ) > is a SUBSHELL
A2
A5
[log.9_0-1264.0] np: 1  1750267869.922563  1750267869.922867  (0.main)  (1264.2):  < 'echo A2' > is a SIMPLE FORK
[log.9_0-1268.0] np: 1  1750267869.922570  1750267869.922893  (0.main)  (1268.4):  < 'echo A5' > is a SIMPLE FORK
A1
[log.9_0-1264.1] np: 1  1750267869.923271  1750267869.923328  (0.main)  (1264.2):  < 'echo A1' > is a NORMAL COMMAND
[log.9_0-1266] np: 1  1750267869.917608  1750267869.923790  (0.main)  (1266.3):  < pid: 1266 ( <-- 1230 ) > is a BACKGROUND FORK
[log.9] np: 1  1750267869.917608  1750267869.923946  (0.main)  (1230.1):  < 'gg 16' > is a FUNCTION (P)
[log.9_0-1271] np: 1  1750267869.917608  1750267869.923855  (0.main)  (1271.4):  < pid: 1271 ( <-- 1230 ) > is a BACKGROUND FORK
A3
A4
[log.9_0-1266.0] np: 1  1750267869.924321  1750267869.924378  (0.main)  (1266.3):  < 'echo A3' > is a NORMAL COMMAND
[log.9_0-1271.0] np: 1  1750267869.924338  1750267869.924388  (0.main)  (1271.4):  < 'echo A4' > is a NORMAL COMMAND
[log.10] np: 1  1750267869.924318  1750267869.924561  (0.main)  (1230.1):  < $'cat <<EOF\nfoo\nbar\nbaz\nEOF\n' > is a NORMAL COMMAND
[log.11] np: 1  1750267869.924958  1750267869.925223  (0.main)  (1230.1):  < 'grep foo' > is a NORMAL COMMAND
[log.12] np: 1  1750267869.925582  1750267869.925905  (0.main)  (1230.1):  < 'sed '\''s/o/O/g'\''' > is a NORMAL COMMAND
1
[log.13] np: 4  1750267869.926243  1750267869.927961  (0.main)  (1230.1):  < 'wc -l' > is a NORMAL COMMAND
[log.14_0-1276] np: 4  1750267869.928355  1750267869.928876  (0.main)  (1276.2):  < pid: 1276 ( <-- 1230 ) > is a SUBSHELL
today is 2025-06-18
[log.14] np: 1  1750267869.928355  1750267869.930549  (0.main)  (1230.1):  < 'echo "today is $(date +%Y-%m-%d)"' > is a NORMAL COMMAND
[log.15_0-1277] np: 1  1750267869.930978  1750267869.931667  (0.main)  (1277.2):  < pid: 1277 ( <-- 1230 ) > is a SUBSHELL
[log.15_0-1278] np: 1  1750267869.930978  1750267869.931748  (0.main)  (1278.3):  < pid: 1278 ( <-- 1230 ) > is a SUBSHELL
[log.15_0-1278.0] np: 1  1750267869.932382  1750267869.932444  (0.main)  (1278.3):  < 'echo nested' > is a NORMAL COMMAND
[log.15_0-1278.1] np: 1  1750267869.932905  1750267869.932960  (0.main)  (1278.3):  < 'echo subshell' > is a NORMAL COMMAND
[log.15_0-1277.0] np: 2  1750267869.932111  1750267869.933832  (0.main)  (1277.2):  < 'grep sub' > is a NORMAL COMMAND
[log.15] np: 1  1750267869.930978  1750267869.934536  (0.main)  (1230.1):  < 'x=$( ( echo nested; echo subshell ) | grep sub)' > is a NORMAL COMMAND
[log.16_0-1280] np: 1  1750267869.934922  1750267869.935366  (0.main)  (1280.2):  < pid: 1280 ( <-- 1230 ) > is a SUBSHELL
[log.16_0-1281] np: 1  1750267869.934922  1750267869.935541  (0.main)  (1281.2):  < pid: 1281 ( <-- 1230 ) > is a SUBSHELL
1,22c1
< bin
< boot
< dev
< etc
< home
< lib
< lib32
< lib64
< lib.usr-is-merged
< media
< mnt
< opt
< proc
< root
< run
< sbin
< script
< srv
< sys
< tmp
< usr
< var
---
> hsperfdata_runner32
[log.16] np: 1  1750267869.934922  1750267869.937675  (0.main)  (1230.1):  < 'diff <(ls /) <(ls /tmp)' > is a SIMPLE FORK
[log.17_0-1283] np: 1  1750267869.938066  1750267869.938393  (0.main)  (1283.2):  < pid: 1283 ( <-- 1230 ) > is a SUBSHELL
[log.17] np: 1  1750267869.938066  1750267869.939877  (0.main)  (1230.1):  < 'grep pattern <(sed '\''s/^/>>/'\'' > /dev/null)' > is a SIMPLE FORK
[log.17_0-1285] np: 1  1750267869.938066  1750267869.939968  (0.main)  (1285.2):  < pid: 1285 ( <-- 1230 ) > is a BACKGROUND FORK
[log.17_0-1285.0] np: 1  1750267869.940439  1750267869.940483  (0.main)  (1285.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17_0-1285.1] np: 1  1750267869.940858  1750267869.940908  (0.main)  (1285.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.18] np: 1  1750267869.940289  1750267869.940946  (0.main)  (1230.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 1
[log.19] np: 1  1750267869.941380  1750267869.941421  (0.main)  (1230.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.17_0-1285.2] np: 1  1750267869.941247  1750267869.952458  (0.main)  (1285.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.17_0-1285.3] np: 1  1750267869.952892  1750267869.952924  (0.main)  (1285.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17_0-1285.4] np: 1  1750267869.953279  1750267869.953318  (0.main)  (1285.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.20] np: 1  1750267869.941853  1750267869.953367  (0.main)  (1230.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 2
[log.21] np: 1  1750267869.953823  1750267869.953894  (0.main)  (1230.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.17_0-1285.5] np: 1  1750267869.953666  1750267869.964889  (0.main)  (1285.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.17_0-1285.6] np: 1  1750267869.965335  1750267869.965375  (0.main)  (1285.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17_0-1285.7] np: 1  1750267869.965766  1750267869.965818  (0.main)  (1285.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.22] np: 1  1750267869.954174  1750267869.965888  (0.main)  (1230.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 3
[log.23] np: 1  1750267869.966312  1750267869.966368  (0.main)  (1230.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.17_0-1285.8] np: 1  1750267869.966095  1750267869.977674  (0.main)  (1285.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.24] np: 1  1750267869.966712  1750267869.978497  (0.main)  (1230.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
[log.25] np: 1  1750267869.978959  1750267869.978998  (0.main)  (1230.1):  < 'let "x = 5 + 6"' > is a NORMAL COMMAND
[log.26] np: 1  1750267869.979339  1750267869.979374  (0.main)  (1230.1):  < 'arr=(one two three)' > is a NORMAL COMMAND
one two three
[log.27] np: 1  1750267869.979759  1750267869.979804  (0.main)  (1230.1):  < 'echo ${arr[@]}' > is a NORMAL COMMAND
[log.28] np: 1  1750267869.980044  1750267869.980069  (0.main)  (1230.1):  < '((i=0))' > is a NORMAL COMMAND
[log.29] np: 1  1750267869.980297  1750267869.980322  (0.main)  (1230.1):  < '((i<3))' > is a NORMAL COMMAND
0
[log.30] np: 1  1750267869.980554  1750267869.980586  (0.main)  (1230.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.31] np: 1  1750267869.980903  1750267869.980929  (0.main)  (1230.1):  < '((i++))' > is a NORMAL COMMAND
[log.32] np: 1  1750267869.981155  1750267869.981180  (0.main)  (1230.1):  < '((i<3))' > is a NORMAL COMMAND
1
[log.33] np: 1  1750267869.981400  1750267869.981430  (0.main)  (1230.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.34] np: 1  1750267869.981653  1750267869.981676  (0.main)  (1230.1):  < '((i++))' > is a NORMAL COMMAND
[log.35] np: 1  1750267869.981986  1750267869.982025  (0.main)  (1230.1):  < '((i<3))' > is a NORMAL COMMAND
2
[log.36] np: 1  1750267869.982363  1750267869.982404  (0.main)  (1230.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.37] np: 1  1750267869.982768  1750267869.982803  (0.main)  (1230.1):  < '((i++))' > is a NORMAL COMMAND
[log.38] np: 1  1750267869.983166  1750267869.983217  (0.main)  (1230.1):  < '((i<3))' > is a NORMAL COMMAND
[log.39] np: 1  1750267869.983549  1750267869.983575  (0.main)  (1230.1):  < 'cmd="echo inside-eval"' > is a NORMAL COMMAND
[log.40] np: 1  1750267869.983841  1750267869.983872  (0.main)  (1230.1):  < 'eval "$cmd"' > is a NORMAL COMMAND
inside-eval
[log.41] np: 1  1750267869.984175  1750267869.984208  (0.main)  (1230.1):  < 'echo inside-eval' > is a NORMAL COMMAND
[log.42] np: 1  1750267869.984430  1750267869.984458  (0.main)  (1230.1):  < 'eval "eval \"$cmd\""' > is a NORMAL COMMAND
[log.43] np: 1  1750267869.984731  1750267869.984767  (0.main)  (1230.1):  < 'eval "echo inside-eval"' > is a NORMAL COMMAND
inside-eval

:<<'EOF'

EOF



# sorted

:<<'EOF
[log.0] np: 1  1750267869.904625  1750267869.904671  (0.main)  (1230.1):  < 'echo 0' > is a NORMAL COMMAND
[log.0_0-1232.0] np: 1  1750267869.904665  1750267869.904714  (0.main)  (1232.2):  < 'echo' > is a NORMAL COMMAND
[log.0_0-1232] np: 1  1750267869.903638  1750267869.904167  (0.main)  (1232.2):  < pid: 1232 ( <-- 1230 ) > is a BACKGROUND FORK
[log.0_0-1233.0] np: 1  1750267869.906232  1750267869.906271  (0.main)  (1233.2):  < 'echo B' > is a NORMAL COMMAND
[log.0_0-1233] np: 1  1750267869.903638  1750267869.905887  (0.main)  (1233.2):  < pid: 1233 ( <-- 1230 ) > is a BACKGROUND FORK
[log.0_0-1234.0] np: 1  1750267869.905015  1750267869.905307  (0.main)  (1234.3):  < 'echo A' > is a SIMPLE FORK
[log.0_0-1234] np: 1  1750267869.903638  1750267869.904539  (0.main)  (1234.3):  < pid: 1234 ( <-- 1230 ) > is a BACKGROUND FORK
[log.1] np: 1  1750267869.905098  1750267869.906288  (0.main)  (1230.1):  < 'echo 1' > is a NORMAL COMMAND
[log.1_0-1236.0] np: 1  1750267869.905834  1750267869.905887  (0.main)  (1236.2):  < 'echo 2' > is a NORMAL COMMAND
[log.1_0-1236] np: 1  1750267869.905098  1750267869.905464  (0.main)  (1236.2):  < pid: 1236 ( <-- 1230 ) > is a SUBSHELL
[log.2] np: 1  1750267869.906678  1750267869.906970  (0.main)  (1230.1):  < 'echo 3' > is a SIMPLE FORK
[log.3] np: 1  1750267869.907324  1750267869.911253  (0.main)  (1230.1):  < 'echo 4' > is a SIMPLE FORK
[log.3_0-1239.0] np: 1  1750267869.908278  1750267869.908317  (0.main)  (1239.2):  < 'echo 5' > is a NORMAL COMMAND
[log.3_0-1239] np: 1  1750267869.907324  1750267869.907847  (0.main)  (1239.2):  < pid: 1239 ( <-- 1230 ) > is a BACKGROUND FORK
[log.3_0-1240.0] np: 1  1750267869.908314  1750267869.908524  (0.main)  (1240.2):  < 'echo 6' > is a SIMPLE FORK
[log.3_0-1240] np: 1  1750267869.907324  1750267869.907965  (0.main)  (1240.2):  < pid: 1240 ( <-- 1230 ) > is a SUBSHELL
[log.3_0-1242.0] np: 1  1750267869.909575  1750267869.909622  (0.main)  (1242.2):  < 'echo 7' > is a NORMAL COMMAND
[log.3_0-1242] np: 1  1750267869.907324  1750267869.909257  (0.main)  (1242.2):  < pid: 1242 ( <-- 1230 ) > is a BACKGROUND FORK
[log.3_0-1243.0] np: 1  1750267869.909711  1750267869.909767  (0.main)  (1243.2):  < 'echo 8' > is a NORMAL COMMAND
[log.3_0-1243] np: 1  1750267869.907324  1750267869.909399  (0.main)  (1243.2):  < pid: 1243 ( <-- 1230 ) > is a SUBSHELL
[log.3_0-1244.0] np: 1  1750267869.910890  1750267869.911172  (0.main)  (1244.2):  < 'echo 9' > is a SIMPLE FORK *
[log.3_0-1244] np: 1  1750267869.907324  1750267869.910495  (0.main)  (1244.2):  < pid: 1244 ( <-- 1230 ) > is a BACKGROUND FORK
[log.3_0-1245.0] np: 1  1750267869.911024  1750267869.911067  (0.main)  (1245.2):  < 'echo 9.1' > is a NORMAL COMMAND
[log.3_0-1245.1] np: 1  1750267869.912133  1750267869.912420  (0.main)  (1245.2):  < 'echo 9.2' > is a SIMPLE FORK
[log.3_0-1245] np: 1  1750267869.907324  1750267869.910567  (0.main)  (1245.2):  < pid: 1245 ( <-- 1230 ) > is a BACKGROUND FORK
[log.3_0-1246.0] np: 1  1750267869.911222  1750267869.911473  (0.main)  (1246.2):  < 'echo 9.1a' > is a SIMPLE FORK *
[log.3_0-1246.1] np: 1  1750267869.912166  1750267869.912225  (0.main)  (1246.2):  < 'echo 9.2a' > is a NORMAL COMMAND
[log.3_0-1246] np: 1  1750267869.907324  1750267869.910742  (0.main)  (1246.2):  < pid: 1246 ( <-- 1230 ) > is a BACKGROUND FORK
[log.3_0-1247.0] np: 1  1750267869.912041  1750267869.913338  (0.main)  (1247.2):  < 'echo 9.1b' > is a NORMAL COMMAND
[log.3_0-1247.1] np: 1  1750267869.913979  1750267869.914354  (0.main)  (1247.2):  < 'echo 9.2b' > is a SIMPLE FORK
[log.3_0-1247] np: 1  1750267869.907324  1750267869.910875  (0.main)  (1247.2):  < pid: 1247 ( <-- 1230 ) > is a BACKGROUND FORK
[log.3_0-1248.0] np: 1  1750267869.911537  1750267869.911830  (0.main)  (1248.2):  < 'echo 9.1c' > is a SIMPLE FORK *
[log.3_0-1248.1] np: 1  1750267869.912191  1750267869.912238  (0.main)  (1248.2):  < 'echo 9.2c' > is a NORMAL COMMAND
[log.3_0-1248] np: 1  1750267869.907324  1750267869.911046  (0.main)  (1248.2):  < pid: 1248 ( <-- 1230 ) > is a BACKGROUND FORK
[log.3_0-1249.0] np: 1  1750267869.913371  1750267869.916373  (0.main)  (1249.2):  < 'echo 9.999' > is a NORMAL COMMAND
[log.3_0-1249.0_0-1259.0] np: 1  1750267869.914825  1750267869.915236  (0.main)  (1259.3):  < 'echo 9.3' > is a SIMPLE FORK
[log.3_0-1249.0_0-1259.1] np: 1  1750267869.915669  1750267869.915736  (0.main)  (1259.3):  < 'echo 9.4' > is a NORMAL COMMAND
[log.3_0-1249.0_0-1259] np: 1  1750267869.913371  1750267869.914310  (0.main)  (1259.3):  < pid: 1259 ( <-- 1249 ) > is a BACKGROUND FORK
[log.3_0-1249.1] np: 1  1750267869.916792  1750267869.916844  (0.main)  (1249.2):  < 'echo 9.5' > is a NORMAL COMMAND
[log.3_0-1249] np: 1  1750267869.907324  1750267869.911578  (0.main)  (1249.2):  < pid: 1249 ( <-- 1230 ) > is a BACKGROUND FORK
[log.3_0-1251.0] np: 1  1750267869.912957  1750267869.913256  (0.main)  (1251.2):  < 'echo 10' > is a SIMPLE FORK *
[log.3_0-1251] np: 1  1750267869.907324  1750267869.911370  (0.main)  (1251.2):  < pid: 1251 ( <-- 1230 ) > is a BACKGROUND FORK
[log.4] np: 1  1750267869.912134  1750267869.912187  (0.main)  (1230.1):  < 'echo 11' > is a NORMAL COMMAND
[log.5] np: 1  1750267869.912514  1750267869.915241  (0.main)  (1230.1):  < 'echo 12' > is a SIMPLE FORK
[log.5_0-1256.0] np: 1  1750267869.914072  1750267869.914193  (0.main)  (1256.2):  < 'echo 13' > is a NORMAL COMMAND
[log.5_0-1256] np: 1  1750267869.912514  1750267869.913369  (0.main)  (1256.2):  < pid: 1256 ( <-- 1230 ) > is a BACKGROUND FORK
[log.5_0-1257.0] np: 1  1750267869.914597  1750267869.914648  (0.main)  (1257.2):  < 'echo 14' > is a NORMAL COMMAND
[log.5_0-1257] np: 1  1750267869.912514  1750267869.913392  (0.main)  (1257.2):  < pid: 1257 ( <-- 1230 ) > is a SUBSHELL
[log.7.0] np: 1  1750267869.915806  1750267869.915840  (2.ff)  (1230.1):  < 'ff 15' > is a FUNCTION (C)
[log.7.1] np: 1  1750267869.916177  1750267869.916225  (2.ff)  (1230.1):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.7] np: 1  1750267869.915478  1750267869.917382  (0.main)  (1230.1):  < 'ff 15' > is a FUNCTION (P)
[log.9.0] np: 1  1750267869.917851  1750267869.917872  (2.gg)  (1230.1):  < 'gg 16' > is a FUNCTION (C)
[log.9.1] np: 1  1750267869.918065  1750267869.918094  (2.gg)  (1230.1):  < 'echo "$*"' > is a NORMAL COMMAND
[log.9.3.0] np: 1  1750267869.918557  1750267869.918578  (3.ff)  (1230.1):  < 'ff "$@"' > is a FUNCTION (C)
[log.9.3.1] np: 1  1750267869.918846  1750267869.918881  (3.ff)  (1230.1):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.9.3] np: 1  1750267869.918331  1750267869.919779  (2.gg)  (1230.1):  < 'ff "$@"' > is a FUNCTION (P)
[log.9] np: 1  1750267869.917608  1750267869.923946  (0.main)  (1230.1):  < 'gg 16' > is a FUNCTION (P)
[log.9_0-1262.0] np: 1  1750267869.921580  1750267869.921901  (0.main)  (1262.2):  < 'echo a' > is a SIMPLE FORK
[log.9_0-1262] np: 1  1750267869.917608  1750267869.921147  (0.main)  (1262.2):  < pid: 1262 ( <-- 1230 ) > is a BACKGROUND FORK
[log.9_0-1264.0] np: 1  1750267869.922563  1750267869.922867  (0.main)  (1264.2):  < 'echo A2' > is a SIMPLE FORK
[log.9_0-1264.1] np: 1  1750267869.923271  1750267869.923328  (0.main)  (1264.2):  < 'echo A1' > is a NORMAL COMMAND
[log.9_0-1264] np: 1  1750267869.917608  1750267869.922036  (0.main)  (1264.2):  < pid: 1264 ( <-- 1230 ) > is a SUBSHELL
[log.9_0-1265.0] np: 1  1750267869.922064  1750267869.922115  (0.main)  (1265.3):  < 'echo b' > is a NORMAL COMMAND
[log.9_0-1265] np: 1  1750267869.917608  1750267869.921583  (0.main)  (1265.3):  < pid: 1265 ( <-- 1230 ) > is a BACKGROUND FORK
[log.9_0-1266.0] np: 1  1750267869.924321  1750267869.924378  (0.main)  (1266.3):  < 'echo A3' > is a NORMAL COMMAND
[log.9_0-1266] np: 1  1750267869.917608  1750267869.923790  (0.main)  (1266.3):  < pid: 1266 ( <-- 1230 ) > is a BACKGROUND FORK
[log.9_0-1268.0] np: 1  1750267869.922570  1750267869.922893  (0.main)  (1268.4):  < 'echo A5' > is a SIMPLE FORK
[log.9_0-1268] np: 1  1750267869.917608  1750267869.922082  (0.main)  (1268.4):  < pid: 1268 ( <-- 1230 ) > is a SUBSHELL
[log.9_0-1271.0] np: 1  1750267869.924338  1750267869.924388  (0.main)  (1271.4):  < 'echo A4' > is a NORMAL COMMAND
[log.9_0-1271] np: 1  1750267869.917608  1750267869.923855  (0.main)  (1271.4):  < pid: 1271 ( <-- 1230 ) > is a BACKGROUND FORK
[log.10] np: 1  1750267869.924318  1750267869.924561  (0.main)  (1230.1):  < $'cat <<EOF\nfoo\nbar\nbaz\nEOF\n' > is a NORMAL COMMAND
[log.11] np: 1  1750267869.924958  1750267869.925223  (0.main)  (1230.1):  < 'grep foo' > is a NORMAL COMMAND
[log.12] np: 1  1750267869.925582  1750267869.925905  (0.main)  (1230.1):  < 'sed '\''s/o/O/g'\''' > is a NORMAL COMMAND
[log.13] np: 4  1750267869.926243  1750267869.927961  (0.main)  (1230.1):  < 'wc -l' > is a NORMAL COMMAND
[log.14] np: 1  1750267869.928355  1750267869.930549  (0.main)  (1230.1):  < 'echo "today is $(date +%Y-%m-%d)"' > is a NORMAL COMMAND
[log.14_0-1276] np: 4  1750267869.928355  1750267869.928876  (0.main)  (1276.2):  < pid: 1276 ( <-- 1230 ) > is a SUBSHELL
[log.15] np: 1  1750267869.930978  1750267869.934536  (0.main)  (1230.1):  < 'x=$( ( echo nested; echo subshell ) | grep sub)' > is a NORMAL COMMAND
[log.15_0-1277.0] np: 2  1750267869.932111  1750267869.933832  (0.main)  (1277.2):  < 'grep sub' > is a NORMAL COMMAND
[log.15_0-1277] np: 1  1750267869.930978  1750267869.931667  (0.main)  (1277.2):  < pid: 1277 ( <-- 1230 ) > is a SUBSHELL
[log.15_0-1278.0] np: 1  1750267869.932382  1750267869.932444  (0.main)  (1278.3):  < 'echo nested' > is a NORMAL COMMAND
[log.15_0-1278.1] np: 1  1750267869.932905  1750267869.932960  (0.main)  (1278.3):  < 'echo subshell' > is a NORMAL COMMAND
[log.15_0-1278] np: 1  1750267869.930978  1750267869.931748  (0.main)  (1278.3):  < pid: 1278 ( <-- 1230 ) > is a SUBSHELL
[log.16] np: 1  1750267869.934922  1750267869.937675  (0.main)  (1230.1):  < 'diff <(ls /) <(ls /tmp)' > is a SIMPLE FORK
[log.16_0-1280] np: 1  1750267869.934922  1750267869.935366  (0.main)  (1280.2):  < pid: 1280 ( <-- 1230 ) > is a SUBSHELL
[log.16_0-1281] np: 1  1750267869.934922  1750267869.935541  (0.main)  (1281.2):  < pid: 1281 ( <-- 1230 ) > is a SUBSHELL
[log.17] np: 1  1750267869.938066  1750267869.939877  (0.main)  (1230.1):  < 'grep pattern <(sed '\''s/^/>>/'\'' > /dev/null)' > is a SIMPLE FORK
[log.17_0-1283] np: 1  1750267869.938066  1750267869.938393  (0.main)  (1283.2):  < pid: 1283 ( <-- 1230 ) > is a SUBSHELL
[log.17_0-1285.0] np: 1  1750267869.940439  1750267869.940483  (0.main)  (1285.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17_0-1285.1] np: 1  1750267869.940858  1750267869.940908  (0.main)  (1285.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.17_0-1285.2] np: 1  1750267869.941247  1750267869.952458  (0.main)  (1285.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.17_0-1285.3] np: 1  1750267869.952892  1750267869.952924  (0.main)  (1285.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17_0-1285.4] np: 1  1750267869.953279  1750267869.953318  (0.main)  (1285.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.17_0-1285.5] np: 1  1750267869.953666  1750267869.964889  (0.main)  (1285.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.17_0-1285.6] np: 1  1750267869.965335  1750267869.965375  (0.main)  (1285.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17_0-1285.7] np: 1  1750267869.965766  1750267869.965818  (0.main)  (1285.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.17_0-1285.8] np: 1  1750267869.966095  1750267869.977674  (0.main)  (1285.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.17_0-1285] np: 1  1750267869.938066  1750267869.939968  (0.main)  (1285.2):  < pid: 1285 ( <-- 1230 ) > is a BACKGROUND FORK
[log.18] np: 1  1750267869.940289  1750267869.940946  (0.main)  (1230.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
[log.19] np: 1  1750267869.941380  1750267869.941421  (0.main)  (1230.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.20] np: 1  1750267869.941853  1750267869.953367  (0.main)  (1230.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
[log.21] np: 1  1750267869.953823  1750267869.953894  (0.main)  (1230.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.22] np: 1  1750267869.954174  1750267869.965888  (0.main)  (1230.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
[log.23] np: 1  1750267869.966312  1750267869.966368  (0.main)  (1230.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.24] np: 1  1750267869.966712  1750267869.978497  (0.main)  (1230.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
[log.25] np: 1  1750267869.978959  1750267869.978998  (0.main)  (1230.1):  < 'let "x = 5 + 6"' > is a NORMAL COMMAND
[log.26] np: 1  1750267869.979339  1750267869.979374  (0.main)  (1230.1):  < 'arr=(one two three)' > is a NORMAL COMMAND
[log.27] np: 1  1750267869.979759  1750267869.979804  (0.main)  (1230.1):  < 'echo ${arr[@]}' > is a NORMAL COMMAND
[log.28] np: 1  1750267869.980044  1750267869.980069  (0.main)  (1230.1):  < '((i=0))' > is a NORMAL COMMAND
[log.29] np: 1  1750267869.980297  1750267869.980322  (0.main)  (1230.1):  < '((i<3))' > is a NORMAL COMMAND
[log.30] np: 1  1750267869.980554  1750267869.980586  (0.main)  (1230.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.31] np: 1  1750267869.980903  1750267869.980929  (0.main)  (1230.1):  < '((i++))' > is a NORMAL COMMAND
[log.32] np: 1  1750267869.981155  1750267869.981180  (0.main)  (1230.1):  < '((i<3))' > is a NORMAL COMMAND
[log.33] np: 1  1750267869.981400  1750267869.981430  (0.main)  (1230.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.34] np: 1  1750267869.981653  1750267869.981676  (0.main)  (1230.1):  < '((i++))' > is a NORMAL COMMAND
[log.35] np: 1  1750267869.981986  1750267869.982025  (0.main)  (1230.1):  < '((i<3))' > is a NORMAL COMMAND
[log.36] np: 1  1750267869.982363  1750267869.982404  (0.main)  (1230.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.37] np: 1  1750267869.982768  1750267869.982803  (0.main)  (1230.1):  < '((i++))' > is a NORMAL COMMAND
[log.38] np: 1  1750267869.983166  1750267869.983217  (0.main)  (1230.1):  < '((i<3))' > is a NORMAL COMMAND
[log.39] np: 1  1750267869.983549  1750267869.983575  (0.main)  (1230.1):  < 'cmd="echo inside-eval"' > is a NORMAL COMMAND
[log.40] np: 1  1750267869.983841  1750267869.983872  (0.main)  (1230.1):  < 'eval "$cmd"' > is a NORMAL COMMAND
[log.41] np: 1  1750267869.984175  1750267869.984208  (0.main)  (1230.1):  < 'echo inside-eval' > is a NORMAL COMMAND
[log.42] np: 1  1750267869.984430  1750267869.984458  (0.main)  (1230.1):  < 'eval "eval \"$cmd\""' > is a NORMAL COMMAND
[log.43] np: 1  1750267869.984731  1750267869.984767  (0.main)  (1230.1):  < 'eval "echo inside-eval"' > is a NORMAL COMMAND

EOF

###############################################################################################################

(

set -T
set -m

: &

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
subshell_pid=''
nexec0=''
nexecA=(0)
npidwrap=0

next_is_simple_fork_flag=false
this_is_simple_fork_flag=false
skip_debug=false
no_print_flag=false
is_func1=false

last_command=()
npipe=()
starttime=()

fnest=(${#FUNCNAME[@]})
fnest_cur=${#FUNCNAME[@]}

last_command[${fnest_cur}]=''
npipe[${fnest_cur}]='0'
starttime[${fnest_cur}]="${EPOCHREALTIME}"

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap ':' EXIT ;;
            RETURN)  builtin trap  'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]" "npipe[${fnest_cur}]" "starttime[${fnest_cur}]" "nexecA[-1]"
nexec0="${nexec0%.*}"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
}

export -f trap

builtin trap ':' EXIT 
builtin trap 'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]" "npipe[${fnest_cur}]" "starttime[${fnest_cur}]" "nexecA[-1]"
nexec0="${nexec0%.*}"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN

builtin trap 'npipe0=${#PIPESTATUS[@]}
endtime0="${EPOCHREALTIME}"
[[ "${BASH_COMMAND}" == trap* ]] && {
  skip_debug=true
  (( fnest_cur == ${#FUNCNAME[@]} )) && {
    fnest_cur=${#FUNCNAME[@]}
    fnest+=("${#FUNCNAME[@]}")
    last_command+=('')
    nexec0+=".${nexecA[-1]}"
    nexecA+=(0)    
  }
}
${skip_debug} || {
npipe[${fnest_cur}]=${npipe0}
endtime=${endtime0}
is_bg=false
is_subshell=false
is_func=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  if (( last_bg_pid == $! )); then
    (( fnest_cur >= ${#FUNCNAME[@]} )) || {
      no_print_flag=true
      is_func=true
      fnest+=("${#FUNCNAME[@]}")
    }
  else
    is_bg=true
  fi
else
  is_subshell=true
  (( BASHPID < last_pid )) && (( npidwrap++ ))
  subshell_pid=$BASHPID 
  builtin trap '"'"':'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == parent_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
  cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif [[ "${last_command[${fnest_cur}]}" == " (F) "* ]]; then
  cmd_type="FUNCTION (P)"
  last_command[${fnest_cur}]="${last_command[${fnest_cur}]# (F) }"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
elif ${is_func1}; then
  cmd_type="FUNCTION (C)"
  is_func1=false
else
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  ${no_print_flag} || printf '"'"'[log%s.%s] np: %s  %s  %s  (%s.%s)  (%s.%s):  < pid: %s ( <-- %s ) > is a %s\n'"'"' "${nexec0}" "${nexecA[-1]}" "${npipe[${fnest_cur}]}" "${starttime[${fnest_cur}]}" "${endtime}" "${fnest_cur}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "$BASHPID" "$last_pid" "$cmd_type" >&${fd}
  nexec0+=".${nexecA[-1]}_${npidwrap}-${BASHPID}"
  nexecA+=(0)
  parent_pgid="$child_pgid"
  parent_tpid="$child_tpid"
  last_subshell="$BASH_SUBSHELL"
elif [[ ${last_command[${fnest_cur}]} ]]; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  ${no_print_flag} || printf '"'"'[log%s.%s] np: %s  %s  %s  (%s.%s)  (%s.%s):  < %s > is a %s\n'"'"' "${nexec0}" "${nexecA[-1]}" "${npipe[${fnest_cur}]}" "${starttime[${fnest_cur}]}" "${endtime}" "${fnest_cur}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "${last_command[${fnest_cur}]@Q}" "$cmd_type"  >&${fd}
  (( nexecA[-1]++ ))
fi 
if ${is_func}; then
  nexec0+=".${nexecA[-1]}"
  nexecA+=(0)    
  last_command[${fnest_cur}]=" (F) ${BASH_COMMAND}"
  npipe[${#FUNCNAME[@]}]="${npipe[${fnest_cur}]}"
  fnest_cur="${#FUNCNAME[@]}"
  last_command[${fnest_cur}]="${BASH_COMMAND}"
  no_print_flag=false
  is_func1=true
else
  last_command[${fnest_cur}]="$BASH_COMMAND"
fi
last_bg_pid="$!"
last_pid="$BASHPID"
starttime[${fnest_cur}]="${EPOCHREALTIME}"
}' DEBUG

{ echo ; } &
{ ( echo A & ); echo B; } &

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &

( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

trap 'echo got USR1; sleep .01' USR1
kill -USR1 $$
echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done
    
builtin trap - DEBUG EXIT RETURN

) {fd}>&2



:<<'EOF'

0
[log.0] np: 1  1750267277.640778  1750267277.641228  (0.main)  (2606.2):  < pid: 2606 ( <-- 2604 ) > is a BACKGROUND FORK

[log.0] np: 1  1750267277.641421  1750267277.641483  (0.main)  (2604.1):  < 'echo 0' > is a NORMAL COMMAND
1
[log.0] np: 1  1750267277.640778  1750267277.641465  (0.main)  (2608.3):  < pid: 2608 ( <-- 2604 ) > is a BACKGROUND FORK
[log.0_0-2606.0] np: 1  1750267277.641674  1750267277.641744  (0.main)  (2606.2):  < 'echo' > is a NORMAL COMMAND
A
[log.0_0-2608.0] np: 1  1750267277.641895  1750267277.642152  (0.main)  (2608.3):  < 'echo A' > is a SIMPLE FORK
[log.1] np: 1  1750267277.641824  1750267277.642166  (0.main)  (2609.2):  < pid: 2609 ( <-- 2604 ) > is a SUBSHELL
2
[log.1_0-2609.0] np: 1  1750267277.642573  1750267277.642628  (0.main)  (2609.2):  < 'echo 2' > is a NORMAL COMMAND
[log.0] np: 1  1750267277.640778  1750267277.642739  (0.main)  (2607.2):  < pid: 2607 ( <-- 2604 ) > is a BACKGROUND FORK
B
[log.0_0-2607.0] np: 1  1750267277.643241  1750267277.643288  (0.main)  (2607.2):  < 'echo B' > is a NORMAL COMMAND
[log.1] np: 1  1750267277.641824  1750267277.643273  (0.main)  (2604.1):  < 'echo 1' > is a NORMAL COMMAND
3
[log.2] np: 1  1750267277.643595  1750267277.643852  (0.main)  (2604.1):  < 'echo 3' > is a SIMPLE FORK
4
[log.3] np: 1  1750267277.644200  1750267277.644638  (0.main)  (2613.2):  < pid: 2613 ( <-- 2604 ) > is a BACKGROUND FORK
5
[log.3] np: 1  1750267277.644200  1750267277.644790  (0.main)  (2614.2):  < pid: 2614 ( <-- 2604 ) > is a SUBSHELL
[log.3_0-2613.0] np: 1  1750267277.645036  1750267277.645083  (0.main)  (2613.2):  < 'echo 5' > is a NORMAL COMMAND
6
[log.3_0-2614.0] np: 1  1750267277.645267  1750267277.645461  (0.main)  (2614.2):  < 'echo 6' > is a SIMPLE FORK
[log.3] np: 1  1750267277.644200  1750267277.646236  (0.main)  (2616.2):  < pid: 2616 ( <-- 2604 ) > is a BACKGROUND FORK
[log.3] np: 1  1750267277.644200  1750267277.646360  (0.main)  (2617.2):  < pid: 2617 ( <-- 2604 ) > is a SUBSHELL
7
8
[log.3_0-2617.0] np: 1  1750267277.646666  1750267277.646703  (0.main)  (2617.2):  < 'echo 8' > is a NORMAL COMMAND
[log.3_0-2616.0] np: 1  1750267277.646633  1750267277.646678  (0.main)  (2616.2):  < 'echo 7' > is a NORMAL COMMAND
[log.3] np: 1  1750267277.644200  1750267277.647421  (0.main)  (2618.2):  < pid: 2618 ( <-- 2604 ) > is a BACKGROUND FORK
[log.3] np: 1  1750267277.644200  1750267277.647536  (0.main)  (2619.2):  < pid: 2619 ( <-- 2604 ) > is a BACKGROUND FORK
9.1
9
[log.3] np: 1  1750267277.644200  1750267277.647697  (0.main)  (2620.2):  < pid: 2620 ( <-- 2604 ) > is a BACKGROUND FORK
[log.3_0-2619.0] np: 1  1750267277.647895  1750267277.647935  (0.main)  (2619.2):  < 'echo 9.1' > is a NORMAL COMMAND
[log.3_0-2618.0] np: 1  1750267277.647748  1750267277.647991  (0.main)  (2618.2):  < 'echo 9' > is a SIMPLE FORK *
[log.3] np: 1  1750267277.644200  1750267277.647881  (0.main)  (2621.2):  < pid: 2621 ( <-- 2604 ) > is a BACKGROUND FORK
[log.3] np: 1  1750267277.644200  1750267277.647992  (0.main)  (2622.2):  < pid: 2622 ( <-- 2604 ) > is a BACKGROUND FORK
9.1b
[log.3] np: 1  1750267277.644200  1750267277.648162  (0.main)  (2604.1):  < 'echo 4' > is a SIMPLE FORK
11
[log.3_0-2620.0] np: 1  1750267277.648231  1750267277.648476  (0.main)  (2620.2):  < 'echo 9.1a' > is a SIMPLE FORK *
[log.3_0-2621.0] np: 1  1750267277.648444  1750267277.648491  (0.main)  (2621.2):  < 'echo 9.1b' > is a NORMAL COMMAND
[log.3_0-2619.1] np: 1  1750267277.648253  1750267277.648510  (0.main)  (2619.2):  < 'echo 9.2' > is a SIMPLE FORK
[log.3] np: 1  1750267277.644200  1750267277.648420  (0.main)  (2624.2):  < pid: 2624 ( <-- 2604 ) > is a BACKGROUND FORK
9.2a
9.999
[log.4] np: 1  1750267277.648585  1750267277.648637  (0.main)  (2604.1):  < 'echo 11' > is a NORMAL COMMAND
[log.3_0-2622.0] np: 1  1750267277.648472  1750267277.648712  (0.main)  (2622.2):  < 'echo 9.1c' > is a SIMPLE FORK *
9.2c
9.1a
9.2
[log.3] np: 1  1750267277.644200  1750267277.648785  (0.main)  (2625.2):  < pid: 2625 ( <-- 2604 ) > is a BACKGROUND FORK
[log.3_0-2620.1] np: 1  1750267277.648881  1750267277.648931  (0.main)  (2620.2):  < 'echo 9.2a' > is a NORMAL COMMAND
[log.3_0-2622.1] np: 1  1750267277.649112  1750267277.649161  (0.main)  (2622.2):  < 'echo 9.2c' > is a NORMAL COMMAND
10
9.2b
12
[log.3_0-2621.1] np: 1  1750267277.648887  1750267277.649168  (0.main)  (2621.2):  < 'echo 9.2b' > is a SIMPLE FORK
9.1c
[log.3_0-2625.0] np: 1  1750267277.649252  1750267277.649499  (0.main)  (2625.2):  < 'echo 10' > is a SIMPLE FORK *
[log.5] np: 1  1750267277.649018  1750267277.649748  (0.main)  (2632.2):  < pid: 2632 ( <-- 2604 ) > is a BACKGROUND FORK
[log.5] np: 1  1750267277.649018  1750267277.649769  (0.main)  (2634.2):  < pid: 2634 ( <-- 2604 ) > is a SUBSHELL
13
14
[log.3_0-2624.0] np: 1  1750267277.648922  1750267277.649983  (0.main)  (2630.3):  < pid: 2630 ( <-- 2624 ) > is a BACKGROUND FORK
[log.5_0-2634.0] np: 1  1750267277.650256  1750267277.650311  (0.main)  (2634.2):  < 'echo 14' > is a NORMAL COMMAND
[log.5_0-2632.0] np: 1  1750267277.650256  1750267277.650311  (0.main)  (2632.2):  < 'echo 13' > is a NORMAL COMMAND
9.3
[log.3_0-2624.0_0-2630.0] np: 1  1750267277.650514  1750267277.650809  (0.main)  (2630.3):  < 'echo 9.3' > is a SIMPLE FORK
9.4
[log.3_0-2624.0_0-2630.1] np: 1  1750267277.651038  1750267277.651074  (0.main)  (2630.3):  < 'echo 9.4' > is a NORMAL COMMAND
[log.5] np: 1  1750267277.649018  1750267277.650956  (0.main)  (2604.1):  < 'echo 12' > is a SIMPLE FORK
[log.3_0-2624.0] np: 1  1750267277.648922  1750267277.651530  (0.main)  (2624.2):  < 'echo 9.999' > is a NORMAL COMMAND
9.5
[log.7.0] np: 1  1750267277.651679  1750267277.651702  (2.ff)  (2604.1):  < 'ff 15' > is a FUNCTION (C)
15
[log.3_0-2624.1] np: 1  1750267277.651911  1750267277.651951  (0.main)  (2624.2):  < 'echo 9.5' > is a NORMAL COMMAND
[log.7.1] np: 1  1750267277.651958  1750267277.651992  (2.ff)  (2604.1):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.7] np: 1  1750267277.651331  1750267277.652878  (0.main)  (2604.1):  < 'ff 15' > is a FUNCTION (P)
[log.9.0] np: 1  1750267277.653295  1750267277.653316  (2.gg)  (2604.1):  < 'gg 16' > is a FUNCTION (C)
16
[log.9.1] np: 1  1750267277.653532  1750267277.653563  (2.gg)  (2604.1):  < 'echo "$*"' > is a NORMAL COMMAND
[log.9.3.0] np: 1  1750267277.654022  1750267277.654043  (3.ff)  (2604.1):  < 'ff "$@"' > is a FUNCTION (C)
16
[log.9.3.1] np: 1  1750267277.654238  1750267277.654270  (3.ff)  (2604.1):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.9.3] np: 1  1750267277.653807  1750267277.655125  (2.gg)  (2604.1):  < 'ff "$@"' > is a FUNCTION (P)
[log.9] np: 1  1750267277.653086  1750267277.656252  (0.main)  (2636.2):  < pid: 2636 ( <-- 2604 ) > is a BACKGROUND FORK
[log.9] np: 1  1750267277.653086  1750267277.656558  (0.main)  (2639.3):  < pid: 2639 ( <-- 2604 ) > is a BACKGROUND FORK
a
[log.9] np: 1  1750267277.653086  1750267277.656638  (0.main)  (2638.2):  < pid: 2638 ( <-- 2604 ) > is a SUBSHELL
b
A2
[log.9_0-2636.0] np: 1  1750267277.656683  1750267277.656981  (0.main)  (2636.2):  < 'echo a' > is a SIMPLE FORK
[log.9] np: 1  1750267277.653086  1750267277.656956  (0.main)  (2641.4):  < pid: 2641 ( <-- 2604 ) > is a SUBSHELL
[log.9_0-2639.0] np: 1  1750267277.657033  1750267277.657089  (0.main)  (2639.3):  < 'echo b' > is a NORMAL COMMAND
[log.9_0-2638.0] np: 1  1750267277.657020  1750267277.657222  (0.main)  (2638.2):  < 'echo A2' > is a SIMPLE FORK
A1
A5
[log.9_0-2638.1] np: 1  1750267277.657495  1750267277.657547  (0.main)  (2638.2):  < 'echo A1' > is a NORMAL COMMAND
[log.9_0-2641.0] np: 1  1750267277.657456  1750267277.657737  (0.main)  (2641.4):  < 'echo A5' > is a SIMPLE FORK
[log.9] np: 1  1750267277.653086  1750267277.658098  (0.main)  (2604.1):  < 'gg 16' > is a FUNCTION (P)
[log.9] np: 1  1750267277.653086  1750267277.658406  (0.main)  (2640.3):  < pid: 2640 ( <-- 2604 ) > is a BACKGROUND FORK
A3
[log.10] np: 1  1750267277.658363  1750267277.658550  (0.main)  (2604.1):  < $'cat <<EOF\nfoo\nbar\nbaz\nEOF\n' > is a NORMAL COMMAND
[log.9] np: 1  1750267277.653086  1750267277.658467  (0.main)  (2645.4):  < pid: 2645 ( <-- 2604 ) > is a BACKGROUND FORK
A4
[log.9_0-2640.0] np: 1  1750267277.658758  1750267277.658808  (0.main)  (2640.3):  < 'echo A3' > is a NORMAL COMMAND
[log.9_0-2645.0] np: 1  1750267277.658918  1750267277.658978  (0.main)  (2645.4):  < 'echo A4' > is a NORMAL COMMAND
[log.11] np: 1  1750267277.658829  1750267277.659048  (0.main)  (2604.1):  < 'grep foo' > is a NORMAL COMMAND
[log.12] np: 1  1750267277.659280  1750267277.659475  (0.main)  (2604.1):  < 'sed '\''s/o/O/g'\''' > is a NORMAL COMMAND
1
[log.13] np: 4  1750267277.659741  1750267277.660929  (0.main)  (2604.1):  < 'wc -l' > is a NORMAL COMMAND
[log.14] np: 4  1750267277.661222  1750267277.661580  (0.main)  (2650.2):  < pid: 2650 ( <-- 2604 ) > is a SUBSHELL
today is 2025-06-18
[log.14] np: 1  1750267277.661222  1750267277.664361  (0.main)  (2604.1):  < 'echo "today is $(date +%Y-%m-%d)"' > is a NORMAL COMMAND
[log.15] np: 1  1750267277.664605  1750267277.665101  (0.main)  (2651.2):  < pid: 2651 ( <-- 2604 ) > is a SUBSHELL
[log.15] np: 1  1750267277.664605  1750267277.665174  (0.main)  (2652.3):  < pid: 2652 ( <-- 2604 ) > is a SUBSHELL
[log.15_0-2652.0] np: 1  1750267277.665566  1750267277.665599  (0.main)  (2652.3):  < 'echo nested' > is a NORMAL COMMAND
[log.15_0-2652.1] np: 1  1750267277.665852  1750267277.665888  (0.main)  (2652.3):  < 'echo subshell' > is a NORMAL COMMAND
[log.15_0-2651.0] np: 2  1750267277.665486  1750267277.666917  (0.main)  (2651.2):  < 'grep sub' > is a NORMAL COMMAND
[log.15] np: 1  1750267277.664605  1750267277.667412  (0.main)  (2604.1):  < 'x=$( ( echo nested; echo subshell ) | grep sub)' > is a NORMAL COMMAND
[log.16] np: 1  1750267277.667754  1750267277.668095  (0.main)  (2654.2):  < pid: 2654 ( <-- 2604 ) > is a SUBSHELL
[log.16] np: 1  1750267277.667754  1750267277.668247  (0.main)  (2655.2):  < pid: 2655 ( <-- 2604 ) > is a SUBSHELL
1,22c1
< bin
< boot
< dev
< etc
< home
< lib
< lib32
< lib64
< lib.usr-is-merged
< media
< mnt
< opt
< proc
< root
< run
< sbin
< script
< srv
< sys
< tmp
< usr
< var
---
> hsperfdata_runner33
[log.16] np: 1  1750267277.667754  1750267277.670302  (0.main)  (2604.1):  < 'diff <(ls /) <(ls /tmp)' > is a SIMPLE FORK
[log.17] np: 1  1750267277.670577  1750267277.670920  (0.main)  (2657.2):  < pid: 2657 ( <-- 2604 ) > is a SUBSHELL
[log.17] np: 1  1750267277.670577  1750267277.672109  (0.main)  (2604.1):  < 'grep pattern <(sed '\''s/^/>>/'\'' > /dev/null)' > is a SIMPLE FORK
[log.17] np: 1  1750267277.670577  1750267277.672214  (0.main)  (2659.2):  < pid: 2659 ( <-- 2604 ) > is a BACKGROUND FORK
[log.17_0-2659.0] np: 1  1750267277.672552  1750267277.672581  (0.main)  (2659.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17_0-2659.1] np: 1  1750267277.672844  1750267277.672887  (0.main)  (2659.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.18] np: 1  1750267277.672390  1750267277.672938  (0.main)  (2604.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 1
[log.19] np: 1  1750267277.673361  1750267277.673412  (0.main)  (2604.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.17_0-2659.2] np: 1  1750267277.673252  1750267277.684477  (0.main)  (2659.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.17_0-2659.3] np: 1  1750267277.684914  1750267277.684967  (0.main)  (2659.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17_0-2659.4] np: 1  1750267277.685219  1750267277.685258  (0.main)  (2659.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.20] np: 1  1750267277.673757  1750267277.685320  (0.main)  (2604.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 2
[log.21] np: 1  1750267277.685791  1750267277.685840  (0.main)  (2604.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.17_0-2659.5] np: 1  1750267277.685665  1750267277.696935  (0.main)  (2659.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.17_0-2659.6] np: 1  1750267277.697407  1750267277.697459  (0.main)  (2659.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17_0-2659.7] np: 1  1750267277.697879  1750267277.697929  (0.main)  (2659.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.22] np: 1  1750267277.686115  1750267277.697984  (0.main)  (2604.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 3
[log.23] np: 1  1750267277.698379  1750267277.698421  (0.main)  (2604.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.17_0-2659.8] np: 1  1750267277.698318  1750267277.709671  (0.main)  (2659.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.24] np: 1  1750267277.698830  1750267277.710535  (0.main)  (2604.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
[log.25] np: 1  1750267277.711005  1750267277.711039  (0.main)  (2604.1):  < 'let "x = 5 + 6"' > is a NORMAL COMMAND
[log.26] np: 1  1750267277.711288  1750267277.711318  (0.main)  (2604.1):  < 'arr=(one two three)' > is a NORMAL COMMAND
one two three
[log.27] np: 1  1750267277.711606  1750267277.711661  (0.main)  (2604.1):  < 'echo ${arr[@]}' > is a NORMAL COMMAND
[log.28] np: 1  1750267277.712014  1750267277.712043  (0.main)  (2604.1):  < '((i=0))' > is a NORMAL COMMAND
[log.29] np: 1  1750267277.712277  1750267277.712303  (0.main)  (2604.1):  < '((i<3))' > is a NORMAL COMMAND
0
[log.30] np: 1  1750267277.712548  1750267277.712594  (0.main)  (2604.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.31] np: 1  1750267277.712967  1750267277.712997  (0.main)  (2604.1):  < '((i++))' > is a NORMAL COMMAND
[log.32] np: 1  1750267277.713266  1750267277.713292  (0.main)  (2604.1):  < '((i<3))' > is a NORMAL COMMAND
1
[log.33] np: 1  1750267277.713522  1750267277.713552  (0.main)  (2604.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.34] np: 1  1750267277.713880  1750267277.713920  (0.main)  (2604.1):  < '((i++))' > is a NORMAL COMMAND
[log.35] np: 1  1750267277.714219  1750267277.714245  (0.main)  (2604.1):  < '((i<3))' > is a NORMAL COMMAND
2
[log.36] np: 1  1750267277.714464  1750267277.714493  (0.main)  (2604.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.37] np: 1  1750267277.714740  1750267277.714774  (0.main)  (2604.1):  < '((i++))' > is a NORMAL COMMAND
[log.38] np: 1  1750267277.715117  1750267277.715155  (0.main)  (2604.1):  < '((i<3))' > is a NORMAL COMMAND
[log.39] np: 1  1750267277.715388  1750267277.715413  (0.main)  (2604.1):  < 'cmd="echo inside-eval"' > is a NORMAL COMMAND
[log.40] np: 1  1750267277.715651  1750267277.715680  (0.main)  (2604.1):  < 'eval "$cmd"' > is a NORMAL COMMAND
inside-eval
[log.41] np: 1  1750267277.715999  1750267277.716048  (0.main)  (2604.1):  < 'echo inside-eval' > is a NORMAL COMMAND
[log.42] np: 1  1750267277.716348  1750267277.716377  (0.main)  (2604.1):  < 'eval "eval \"$cmd\""' > is a NORMAL COMMAND
[log.43] np: 1  1750267277.716608  1750267277.716635  (0.main)  (2604.1):  < 'eval "echo inside-eval"' > is a NORMAL COMMAND
inside-eval
[log.44] np: 1  1750267277.720826  1750267277.720864  (0.main)  (2604.1):  < 'kill -USR1 $$' > is a NORMAL COMMAND


EOF



########################################################

(

set -T
set -m

: &

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
subshell_pid=''
nexec0=''
nexecA=(0)
npidwrap=0

next_is_simple_fork_flag=false
this_is_simple_fork_flag=false
skip_debug=false
no_print_flag=false
is_func1=false

last_command=()
npipe=()
starttime=()

fnest=(${#FUNCNAME[@]})
fnest_cur=${#FUNCNAME[@]}

last_command[${fnest_cur}]=''
npipe[${fnest_cur}]='0'
starttime[${fnest_cur}]="${EPOCHREALTIME}"

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap ':' EXIT ;;
            RETURN)  builtin trap  'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]" "npipe[${fnest_cur}]" "starttime[${fnest_cur}]" "nexecA[-1]"
nexec0="${nexec0%.*}"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
}

export -f trap

builtin trap ':' EXIT 
builtin trap 'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]" "npipe[${fnest_cur}]" "starttime[${fnest_cur}]" "nexecA[-1]"
nexec0="${nexec0%.*}"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN

builtin trap 'npipe0=${#PIPESTATUS[@]}
endtime0="${EPOCHREALTIME}"
[[ "${BASH_COMMAND}" == trap* ]] && {
  skip_debug=true
  (( fnest_cur == ${#FUNCNAME[@]} )) && {
    fnest_cur=${#FUNCNAME[@]}
    fnest+=("${#FUNCNAME[@]}")
    last_command+=('')
    nexec0+=".${nexecA[-1]}"
    nexecA+=(0)    
  }
}
${skip_debug} || {
npipe[${fnest_cur}]=${npipe0}
endtime=${endtime0}
is_bg=false
is_subshell=false
is_func=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  if (( last_bg_pid == $! )); then
    (( fnest_cur >= ${#FUNCNAME[@]} )) || {
      no_print_flag=true
      is_func=true
      fnest+=("${#FUNCNAME[@]}")
    }
  else
    is_bg=true
  fi
else
  is_subshell=true
  (( BASHPID < last_pid )) && (( npidwrap++ ))
  subshell_pid=$BASHPID 
  builtin trap '"'"':'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == parent_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
  cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif [[ "${last_command[${fnest_cur}]}" == " (F) "* ]]; then
  cmd_type="FUNCTION (P)"
  last_command[${fnest_cur}]="${last_command[${fnest_cur}]# (F) }"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
elif ${is_func1}; then
  cmd_type="FUNCTION (C)"
  is_func1=false
else
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  ${no_print_flag} || printf '"'"'[log%s.%s_%s.%s] np: %s  %s  %s  (%s.%s)  (%s.%s):  < pid: %s ( <-- %s ) > is a %s\n'"'"' "${nexec0}" "${nexecA[-1]}" "${npidwrap}" "${BASHPID}" "${npipe[${fnest_cur}]}" "${starttime[${fnest_cur}]}" "${endtime}" "${fnest_cur}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "$BASHPID" "$last_pid" "$cmd_type" >&${fd}
  nexec0+=".${nexecA[-1]}"
  nexecA+=(0)
  parent_pgid="$child_pgid"
  parent_tpid="$child_tpid"
  last_subshell="$BASH_SUBSHELL"
elif [[ ${last_command[${fnest_cur}]} ]]; then
  (( nexecA[-1]++ ))
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  ${no_print_flag} || printf '"'"'[log%s.%s_%s.%s] np: %s  %s  %s  (%s.%s)  (%s.%s):  < %s > is a %s\n'"'"' "${nexec0}" "${nexecA[-1]}" "${npidwrap}" "${BASHPID}" "${npipe[${fnest_cur}]}" "${starttime[${fnest_cur}]}" "${endtime}" "${fnest_cur}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "${last_command[${fnest_cur}]@Q}" "$cmd_type"  >&${fd}
  parent_pgid="$child_pgid"
fi 
if ${is_func}; then
  nexec0+=".${nexecA[-1]}"
  nexecA+=(0)    
  last_command[${fnest_cur}]=" (F) ${BASH_COMMAND}"
  npipe[${#FUNCNAME[@]}]="${npipe[${fnest_cur}]}"
  fnest_cur="${#FUNCNAME[@]}"
  last_command[${fnest_cur}]="${BASH_COMMAND}"
  no_print_flag=false
  is_func1=true
else
  last_command[${fnest_cur}]="$BASH_COMMAND"
fi
last_bg_pid="$!"
last_pid="$BASHPID"
starttime[${fnest_cur}]="${EPOCHREALTIME}"
}' DEBUG

{ echo ; } &
{ ( echo A & ); echo B; } &

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &

( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

trap 'echo got USR1; sleep .01' USR1
kill -USR1 $$
echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done
    
builtin trap - DEBUG EXIT RETURN

) {fd}>&2

:<<'EOF'
[log.0_0.260] np: 1  1750259449.529142  1750259449.529610  (0.main)  (260.2):  < pid: 260 ( <-- 258 ) > is a BACKGROUND FORK
[log.1_0.258] np: 1  1750259449.529849  1750259449.529898  (0.main)  (258.1):  < 'echo 0' > is a NORMAL COMMAND
[log.0.1_0.260] np: 1  1750259449.529997  1750259449.530046  (0.main)  (260.2):  < 'echo' > is a NORMAL COMMAND
[log.0_0.262] np: 1  1750259449.529142  1750259449.529926  (0.main)  (262.3):  < pid: 262 ( <-- 258 ) > is a BACKGROUND FORK
[log.1_0.263] np: 1  1750259449.530253  1750259449.530646  (0.main)  (263.2):  < pid: 263 ( <-- 258 ) > is a BACKGROUND FORK
[log.0.1_0.262] np: 1  1750259449.530488  1750259449.530741  (0.main)  (262.3):  < 'echo A' > is a SIMPLE FORK
[log.1.1_0.263] np: 1  1750259449.531063  1750259449.531110  (0.main)  (263.2):  < 'echo 2' > is a NORMAL COMMAND
[log.0_0.261] np: 1  1750259449.529142  1750259449.531340  (0.main)  (261.2):  < pid: 261 ( <-- 258 ) > is a BACKGROUND FORK
[log.0.1_0.261] np: 1  1750259449.531658  1750259449.531699  (0.main)  (261.2):  < 'echo B' > is a NORMAL COMMAND
[log.2_0.258] np: 1  1750259449.530253  1750259449.531634  (0.main)  (258.1):  < 'echo 1' > is a NORMAL COMMAND
[log.3_0.258] np: 1  1750259449.532007  1750259449.532282  (0.main)  (258.1):  < 'echo 3' > is a SIMPLE FORK
[log.3_0.267] np: 1  1750259449.532551  1750259449.533001  (0.main)  (267.2):  < pid: 267 ( <-- 258 ) > is a BACKGROUND FORK
[log.3_0.268] np: 1  1750259449.532551  1750259449.533094  (0.main)  (268.2):  < pid: 268 ( <-- 258 ) > is a SUBSHELL
[log.3.1_0.267] np: 1  1750259449.533335  1750259449.533384  (0.main)  (267.2):  < 'echo 5' > is a NORMAL COMMAND
[log.3.1_0.268] np: 1  1750259449.533456  1750259449.533705  (0.main)  (268.2):  < 'echo 6' > is a SIMPLE FORK
[log.3_0.270] np: 1  1750259449.532551  1750259449.534462  (0.main)  (270.2):  < pid: 270 ( <-- 258 ) > is a BACKGROUND FORK
[log.3_0.271] np: 1  1750259449.532551  1750259449.534580  (0.main)  (271.2):  < pid: 271 ( <-- 258 ) > is a SUBSHELL
[log.3.1_0.270] np: 1  1750259449.534763  1750259449.534805  (0.main)  (270.2):  < 'echo 7' > is a NORMAL COMMAND
[log.3.1_0.271] np: 1  1750259449.534934  1750259449.534992  (0.main)  (271.2):  < 'echo 8' > is a NORMAL COMMAND
[log.3_0.272] np: 1  1750259449.532551  1750259449.535758  (0.main)  (272.2):  < pid: 272 ( <-- 258 ) > is a BACKGROUND FORK
[log.3_0.273] np: 1  1750259449.532551  1750259449.535824  (0.main)  (273.2):  < pid: 273 ( <-- 258 ) > is a BACKGROUND FORK
[log.3_0.274] np: 1  1750259449.532551  1750259449.535981  (0.main)  (274.2):  < pid: 274 ( <-- 258 ) > is a BACKGROUND FORK
[log.3.1_0.273] np: 1  1750259449.536135  1750259449.536177  (0.main)  (273.2):  < 'echo 9.1' > is a NORMAL COMMAND
[log.3_0.275] np: 1  1750259449.532551  1750259449.536154  (0.main)  (275.2):  < pid: 275 ( <-- 258 ) > is a BACKGROUND FORK
[log.3.1_0.272] np: 1  1750259449.536108  1750259449.536377  (0.main)  (272.2):  < 'echo 9' > is a SIMPLE FORK *
[log.3_0.276] np: 1  1750259449.532551  1750259449.536300  (0.main)  (276.2):  < pid: 276 ( <-- 258 ) > is a BACKGROUND FORK
[log.4_0.258] np: 1  1750259449.532551  1750259449.536460  (0.main)  (258.1):  < 'echo 4' > is a SIMPLE FORK
[log.3_0.277] np: 1  1750259449.532551  1750259449.536444  (0.main)  (277.2):  < pid: 277 ( <-- 258 ) > is a BACKGROUND FORK
[log.3.1_0.274] np: 1  1750259449.536514  1750259449.536763  (0.main)  (274.2):  < 'echo 9.1a' > is a SIMPLE FORK *
[log.3.2_0.273] np: 1  1750259449.536526  1750259449.536796  (0.main)  (273.2):  < 'echo 9.2' > is a SIMPLE FORK
[log.3.1_0.275] np: 1  1750259449.536742  1750259449.536791  (0.main)  (275.2):  < 'echo 9.1b' > is a NORMAL COMMAND
[log.5_0.258] np: 1  1750259449.536856  1750259449.536904  (0.main)  (258.1):  < 'echo 11' > is a NORMAL COMMAND
[log.3.1_0.276] np: 1  1750259449.536804  1750259449.537063  (0.main)  (276.2):  < 'echo 9.1c' > is a SIMPLE FORK *
[log.3.0_0.283] np: 1  1750259449.536924  1750259449.537363  (0.main)  (283.3):  < pid: 283 ( <-- 277 ) > is a SUBSHELL
[log.3_0.279] np: 1  1750259449.532551  1750259449.537476  (0.main)  (279.2):  < pid: 279 ( <-- 258 ) > is a BACKGROUND FORK
[log.3.2_0.276] np: 1  1750259449.537458  1750259449.537598  (0.main)  (276.2):  < 'echo 9.2c' > is a NORMAL COMMAND
[log.3.2_0.274] np: 1  1750259449.537160  1750259449.537212  (0.main)  (274.2):  < 'echo 9.2a' > is a NORMAL COMMAND
[log.5_0.286] np: 1  1750259449.537317  1750259449.537988  (0.main)  (286.2):  < pid: 286 ( <-- 258 ) > is a BACKGROUND FORK
[log.3.0.1_0.283] np: 1  1750259449.537841  1750259449.538092  (0.main)  (283.3):  < 'echo 9.3' > is a SIMPLE FORK
[log.5_0.287] np: 1  1750259449.537317  1750259449.538062  (0.main)  (287.2):  < pid: 287 ( <-- 258 ) > is a BACKGROUND FORK
[log.3.1_0.279] np: 1  1750259449.537934  1750259449.538217  (0.main)  (279.2):  < 'echo 10' > is a SIMPLE FORK *
[log.3.2_0.275] np: 1  1750259449.537165  1750259449.537486  (0.main)  (275.2):  < 'echo 9.2b' > is a SIMPLE FORK
[log.5.1_0.286] np: 1  1750259449.538460  1750259449.538516  (0.main)  (286.2):  < 'echo 13' > is a NORMAL COMMAND
[log.3.0.2_0.283] np: 1  1750259449.538496  1750259449.538557  (0.main)  (283.3):  < 'echo 9.4' > is a NORMAL COMMAND
[log.5.1_0.287] np: 1  1750259449.538601  1750259449.538657  (0.main)  (287.2):  < 'echo 14' > is a NORMAL COMMAND
[log.3.1_0.277] np: 1  1750259449.536924  1750259449.539201  (0.main)  (277.2):  < 'echo 9.999' > is a NORMAL COMMAND
[log.6_0.258] np: 1  1750259449.537317  1750259449.539254  (0.main)  (258.1):  < 'echo 12' > is a SIMPLE FORK
[log.3.2_0.277] np: 1  1750259449.539480  1750259449.539524  (0.main)  (277.2):  < 'echo 9.5' > is a NORMAL COMMAND
[log.7.1_0.258] np: 1  1750259449.539713  1750259449.539734  (2.ff)  (258.1):  < 'ff 15' > is a FUNCTION (C)
[log.7.2_0.258] np: 1  1750259449.539990  1750259449.540026  (2.ff)  (258.1):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.8_0.258] np: 1  1750259449.539489  1750259449.540881  (0.main)  (258.1):  < 'ff 15' > is a FUNCTION (P)
[log.9.1_0.258] np: 1  1750259449.541362  1750259449.541383  (2.gg)  (258.1):  < 'gg 16' > is a FUNCTION (C)
[log.9.2_0.258] np: 1  1750259449.541576  1750259449.541608  (2.gg)  (258.1):  < 'echo "$*"' > is a NORMAL COMMAND
[log.9.3.1_0.258] np: 1  1750259449.542028  1750259449.542047  (3.ff)  (258.1):  < 'ff "$@"' > is a FUNCTION (C)
[log.9.3.2_0.258] np: 1  1750259449.542269  1750259449.542316  (3.ff)  (258.1):  < 'echo "${*}"' > is a NORMAL COMMAND
[log.9.4_0.258] np: 1  1750259449.541817  1750259449.543153  (2.gg)  (258.1):  < 'ff "$@"' > is a FUNCTION (P)
[log.9_0.290] np: 1  1750259449.541128  1750259449.544289  (0.main)  (290.2):  < pid: 290 ( <-- 258 ) > is a BACKGROUND FORK
[log.9_0.293] np: 1  1750259449.541128  1750259449.544606  (0.main)  (293.3):  < pid: 293 ( <-- 258 ) > is a BACKGROUND FORK
[log.9_0.292] np: 1  1750259449.541128  1750259449.544662  (0.main)  (292.2):  < pid: 292 ( <-- 258 ) > is a SUBSHELL
[log.9.1_0.290] np: 1  1750259449.544639  1750259449.544905  (0.main)  (290.2):  < 'echo a' > is a SIMPLE FORK
[log.9.1_0.293] np: 1  1750259449.544934  1750259449.544994  (0.main)  (293.3):  < 'echo b' > is a NORMAL COMMAND
[log.9_0.295] np: 1  1750259449.541128  1750259449.544958  (0.main)  (295.4):  < pid: 295 ( <-- 258 ) > is a SUBSHELL
[log.9.1_0.292] np: 1  1750259449.545078  1750259449.545328  (0.main)  (292.2):  < 'echo A2' > is a SIMPLE FORK
[log.9.1_0.295] np: 1  1750259449.545479  1750259449.545725  (0.main)  (295.4):  < 'echo A5' > is a SIMPLE FORK
[log.9.2_0.292] np: 1  1750259449.545667  1750259449.545713  (0.main)  (292.2):  < 'echo A1' > is a NORMAL COMMAND
[log.10_0.258] np: 1  1750259449.541128  1750259449.546293  (0.main)  (258.1):  < 'gg 16' > is a FUNCTION (P)
[log.9_0.299] np: 1  1750259449.541128  1750259449.546492  (0.main)  (299.4):  < pid: 299 ( <-- 258 ) > is a BACKGROUND FORK
[log.9_0.294] np: 1  1750259449.541128  1750259449.546495  (0.main)  (294.3):  < pid: 294 ( <-- 258 ) > is a BACKGROUND FORK
[log.9.1_0.299] np: 1  1750259449.546801  1750259449.546841  (0.main)  (299.4):  < 'echo A4' > is a NORMAL COMMAND
[log.11_0.258] np: 1  1750259449.546705  1750259449.546962  (0.main)  (258.1):  < $'cat <<EOF\nfoo\nbar\nbaz\nEOF\n' > is a NORMAL COMMAND
[log.9.1_0.294] np: 1  1750259449.546965  1750259449.547032  (0.main)  (294.3):  < 'echo A3' > is a NORMAL COMMAND
[log.12_0.258] np: 1  1750259449.547397  1750259449.547655  (0.main)  (258.1):  < 'grep foo' > is a NORMAL COMMAND
[log.13_0.258] np: 1  1750259449.547879  1750259449.548074  (0.main)  (258.1):  < 'sed '\''s/o/O/g'\''' > is a NORMAL COMMAND
[log.14_0.258] np: 4  1750259449.548330  1750259449.549534  (0.main)  (258.1):  < 'wc -l' > is a NORMAL COMMAND
[log.14_0.304] np: 4  1750259449.549778  1750259449.550098  (0.main)  (304.2):  < pid: 304 ( <-- 258 ) > is a SUBSHELL
[log.15_0.258] np: 1  1750259449.549778  1750259449.551173  (0.main)  (258.1):  < 'echo "today is $(date +%Y-%m-%d)"' > is a NORMAL COMMAND
[log.15_0.305] np: 1  1750259449.551466  1750259449.551935  (0.main)  (305.2):  < pid: 305 ( <-- 258 ) > is a SUBSHELL
[log.15_0.306] np: 1  1750259449.551466  1750259449.552006  (0.main)  (306.3):  < pid: 306 ( <-- 258 ) > is a SUBSHELL
[log.15.1_0.306] np: 1  1750259449.552368  1750259449.552404  (0.main)  (306.3):  < 'echo nested' > is a NORMAL COMMAND
[log.15.2_0.306] np: 1  1750259449.552615  1750259449.552648  (0.main)  (306.3):  < 'echo subshell' > is a NORMAL COMMAND
[log.15.1_0.305] np: 2  1750259449.552295  1750259449.553450  (0.main)  (305.2):  < 'grep sub' > is a NORMAL COMMAND
[log.16_0.258] np: 1  1750259449.551466  1750259449.554018  (0.main)  (258.1):  < 'x=$( ( echo nested; echo subshell ) | grep sub)' > is a NORMAL COMMAND
[log.16_0.308] np: 1  1750259449.554482  1750259449.554844  (0.main)  (308.2):  < pid: 308 ( <-- 258 ) > is a SUBSHELL
[log.16_0.309] np: 1  1750259449.554482  1750259449.555043  (0.main)  (309.2):  < pid: 309 ( <-- 258 ) > is a SUBSHELL
[log.17_0.258] np: 1  1750259449.554482  1750259449.556455  (0.main)  (258.1):  < 'diff <(ls /) <(ls /tmp)' > is a SIMPLE FORK
[log.17_0.311] np: 1  1750259449.556895  1750259449.557262  (0.main)  (311.2):  < pid: 311 ( <-- 258 ) > is a SUBSHELL
[log.17_0.313] np: 1  1750259449.556895  1750259449.558611  (0.main)  (313.2):  < pid: 313 ( <-- 258 ) > is a BACKGROUND FORK
[log.18_0.258] np: 1  1750259449.556895  1750259449.558546  (0.main)  (258.1):  < 'grep pattern <(sed '\''s/^/>>/'\'' > /dev/null)' > is a SIMPLE FORK
[log.17.1_0.313] np: 1  1750259449.558980  1750259449.559010  (0.main)  (313.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17.2_0.313] np: 1  1750259449.559231  1750259449.559284  (0.main)  (313.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.19_0.258] np: 1  1750259449.559030  1750259449.559321  (0.main)  (258.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
[log.20_0.258] np: 1  1750259449.559797  1750259449.559859  (0.main)  (258.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.17.3_0.313] np: 1  1750259449.559490  1750259449.570415  (0.main)  (313.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.17.4_0.313] np: 1  1750259449.570705  1750259449.570732  (0.main)  (313.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17.5_0.313] np: 1  1750259449.570976  1750259449.571008  (0.main)  (313.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.21_0.258] np: 1  1750259449.560345  1750259449.571081  (0.main)  (258.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
[log.22_0.258] np: 1  1750259449.571576  1750259449.571644  (0.main)  (258.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.17.6_0.313] np: 1  1750259449.571249  1750259449.582151  (0.main)  (313.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.17.7_0.313] np: 1  1750259449.582466  1750259449.582492  (0.main)  (313.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
[log.17.8_0.313] np: 1  1750259449.582727  1750259449.582760  (0.main)  (313.2):  < 'echo "$i"' > is a NORMAL COMMAND
[log.23_0.258] np: 1  1750259449.572103  1750259449.582841  (0.main)  (258.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
[log.24_0.258] np: 1  1750259449.583337  1750259449.583399  (0.main)  (258.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
[log.17.9_0.313] np: 1  1750259449.582997  1750259449.594006  (0.main)  (313.2):  < 'sleep .01' > is a NORMAL COMMAND
[log.25_0.258] np: 1  1750259449.583843  1750259449.594590  (0.main)  (258.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
[log.26_0.258] np: 1  1750259449.595070  1750259449.595126  (0.main)  (258.1):  < 'let "x = 5 + 6"' > is a NORMAL COMMAND
[log.27_0.258] np: 1  1750259449.595610  1750259449.595664  (0.main)  (258.1):  < 'arr=(one two three)' > is a NORMAL COMMAND
[log.28_0.258] np: 1  1750259449.596104  1750259449.596173  (0.main)  (258.1):  < 'echo ${arr[@]}' > is a NORMAL COMMAND
[log.29_0.258] np: 1  1750259449.596648  1750259449.596693  (0.main)  (258.1):  < '((i=0))' > is a NORMAL COMMAND
[log.30_0.258] np: 1  1750259449.597160  1750259449.597210  (0.main)  (258.1):  < '((i<3))' > is a NORMAL COMMAND
[log.31_0.258] np: 1  1750259449.597650  1750259449.597706  (0.main)  (258.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.32_0.258] np: 1  1750259449.598128  1750259449.598174  (0.main)  (258.1):  < '((i++))' > is a NORMAL COMMAND
[log.33_0.258] np: 1  1750259449.598632  1750259449.598679  (0.main)  (258.1):  < '((i<3))' > is a NORMAL COMMAND
[log.34_0.258] np: 1  1750259449.599102  1750259449.599165  (0.main)  (258.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.35_0.258] np: 1  1750259449.599632  1750259449.599681  (0.main)  (258.1):  < '((i++))' > is a NORMAL COMMAND
[log.36_0.258] np: 1  1750259449.600115  1750259449.600163  (0.main)  (258.1):  < '((i<3))' > is a NORMAL COMMAND
[log.37_0.258] np: 1  1750259449.600634  1750259449.600697  (0.main)  (258.1):  < 'echo "$i"' > is a NORMAL COMMAND
[log.38_0.258] np: 1  1750259449.601161  1750259449.601216  (0.main)  (258.1):  < '((i++))' > is a NORMAL COMMAND
[log.39_0.258] np: 1  1750259449.601677  1750259449.601743  (0.main)  (258.1):  < '((i<3))' > is a NORMAL COMMAND
[log.40_0.258] np: 1  1750259449.602226  1750259449.602286  (0.main)  (258.1):  < 'cmd="echo inside-eval"' > is a NORMAL COMMAND
[log.41_0.258] np: 1  1750259449.602727  1750259449.602778  (0.main)  (258.1):  < 'eval "$cmd"' > is a NORMAL COMMAND
[log.42_0.258] np: 1  1750259449.603253  1750259449.603316  (0.main)  (258.1):  < 'echo inside-eval' > is a NORMAL COMMAND
[log.43_0.258] np: 1  1750259449.603763  1750259449.603812  (0.main)  (258.1):  < 'eval "eval \"$cmd\""' > is a NORMAL COMMAND
[log.44_0.258] np: 1  1750259449.604270  1750259449.604322  (0.main)  (258.1):  < 'eval "echo inside-eval"' > is a NORMAL COMMAND

EOF

###################################################################################################

(

set -T
set -m

: &

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
subshell_pid=''
nexec='0'

next_is_simple_fork_flag=false
this_is_simple_fork_flag=false
skip_debug=false
no_print_flag=false
is_func1=false

last_command=()
npipe=()
starttime=()
nexecA=()

fnest=(${#FUNCNAME[@]})
fnest_cur=${#FUNCNAME[@]}

last_command[${fnest_cur}]=''
npipe[${fnest_cur}]='0'
starttime[${fnest_cur}]="${EPOCHREALTIME}"
nexecA[${fnest_cur}]=0

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap ':' EXIT ;;
            RETURN)  builtin trap  'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]" "npipe[${fnest_cur}]" "starttime[${fnest_cur}]" "nexecA[${fnest_cur}]"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
}

export -f trap

builtin trap ':' EXIT 
builtin trap 'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]" "npipe[${fnest_cur}]" "starttime[${fnest_cur}]" "nexecA[${fnest_cur}]"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN

builtin trap 'npipe0=${#PIPESTATUS[@]}
endtime0="${EPOCHREALTIME}"
[[ "${BASH_COMMAND}" == trap* ]] && {
  skip_debug=true
  (( fnest_cur == ${#FUNCNAME[@]} )) && {
    fnest_cur=${#FUNCNAME[@]}
    fnest+=("${#FUNCNAME[@]}")
    last_command+=('')
  }
}
${skip_debug} || {
npipe[${fnest_cur}]=${npipe0}
endtime=${endtime0}
is_bg=false
is_subshell=false
is_func=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  if (( last_bg_pid == $! )); then
    (( fnest_cur >= ${#FUNCNAME[@]} )) || {
      no_print_flag=true
      is_func=true
      fnest+=("${#FUNCNAME[@]}")
    }
  else
    is_bg=true
  fi
else
  is_subshell=true
  subshell_pid=$BASHPID 
  builtin trap '"'"':'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == parent_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
  cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif [[ "${last_command[${fnest_cur}]}" == " (F) "* ]]; then
  cmd_type="FUNCTION (P)"
  last_command[${fnest_cur}]="${last_command[${fnest_cur}]# (F) }"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
elif ${is_func1}; then
  cmd_type="FUNCTION (C)"
  is_func1=false
else
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  ${no_print_flag} || printf '"'"'np: %s  %s  %s  (%s.%s)  (%s.%s):  < pid: %s ( <-- %s )> is a %s\n'"'"' "${npipe[${fnest_cur}]}" "${starttime[${fnest_cur}]}" "${endtime}" "${fnest_cur}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "$BASHPID" "$last_pid" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ ${last_command[${fnest_cur}]} ]]; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  ${no_print_flag} || printf '"'"'np: %s  %s  %s  (%s.%s)  (%s.%s):  < %s > is a %s\n'"'"' "${npipe[${fnest_cur}]}" "${starttime[${fnest_cur}]}" "${endtime}" "${fnest_cur}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "${last_command[${fnest_cur}]@Q}" "$cmd_type"
fi >&$fd
if ${is_func}; then
  last_command[${fnest_cur}]=" (F) $BASH_COMMAND"
  npipe[${#FUNCNAME[@]}]="${npipe[${fnest_cur}]}"
  fnest_cur="${#FUNCNAME[@]}"
  last_command[${fnest_cur}]="$BASH_COMMAND"
  no_print_flag=false
  is_func1=true
else
  last_command[${fnest_cur}]="$BASH_COMMAND"
fi
last_bg_pid=$!
last_pid=$BASHPID
starttime[${fnest_cur}]="${EPOCHREALTIME}"
}' DEBUG

{ echo ; } &
{ ( echo A & ); echo B; } &

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &

( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

trap 'echo got USR1; sleep .01' USR1
kill -USR1 $$
echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done
    
builtin trap - DEBUG EXIT RETURN

) {fd}>&2


(

set -T
set -m

: &

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
subshell_pid=''

next_is_simple_fork_flag=false
this_is_simple_fork_flag=false
skip_debug=false
no_print_flag=false
is_func1=false

last_command=()
npipe=()
starttime=()

fnest=(${#FUNCNAME[@]})
fnest_cur=${#FUNCNAME[@]}

last_command[${fnest_cur}]=''
npipe[${fnest_cur}]='0'
starttime[${fnest_cur}]="${EPOCHREALTIME}"

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap ':' EXIT ;;
            RETURN)  builtin trap  'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]" "npipe[${fnest_cur}]"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
}

export -f trap

builtin trap ':' EXIT 
builtin trap 'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]" "npipe[${fnest_cur}]"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN

builtin trap 'npipe0=${#PIPESTATUS[@]}
endtime0="${EPOCHREALTIME}"
[[ "${BASH_COMMAND}" == trap* ]] && {
  skip_debug=true
  (( fnest_cur == ${#FUNCNAME[@]} )) && {
    fnest_cur=${#FUNCNAME[@]}
    fnest+=("${#FUNCNAME[@]}")
    last_command+=('')
  }
}
${skip_debug} || {
npipe[${fnest_cur}]=${npipe0}
endtime=${endtime0}
is_bg=false
is_subshell=false
is_func=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  if (( last_bg_pid == $! )); then
    (( fnest_cur >= ${#FUNCNAME[@]} )) || {
      no_print_flag=true
      is_func=true
      fnest+=("${#FUNCNAME[@]}")
    }
  else
    is_bg=true
  fi
else
  is_subshell=true
  subshell_pid=$BASHPID 
  builtin trap '"'"':'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == parent_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
  cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif [[ "${last_command[${fnest_cur}]}" == " (F) "* ]]; then
  cmd_type="FUNCTION (P)"
  last_command[${fnest_cur}]="${last_command[${fnest_cur}]# (F) }"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
elif ${is_func1}; then
  cmd_type="FUNCTION (C)"
  is_func1=false
else
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  ${no_print_flag} || printf '"'"'np: %s  %s  %s  (%s.%s)  (%s.%s):  < pid: %s ( <-- %s )> is a %s\n'"'"' "${npipe[${fnest_cur}]}" "${starttime[${fnest_cur}]}" "${endtime}" "${fnest_cur}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "$BASHPID" "$last_pid" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ ${last_command[${fnest_cur}]} ]]; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  ${no_print_flag} || printf '"'"'np: %s  %s  %s  (%s.%s)  (%s.%s):  < %s > is a %s\n'"'"' "${npipe[${fnest_cur}]}" "${starttime[${fnest_cur}]}" "${endtime}" "${fnest_cur}" "${FUNCNAME[0]:-main}" "${BASHPID}" "${BASH_SUBSHELL}" "${last_command[${fnest_cur}]@Q}" "$cmd_type"
fi >&$fd
if ${is_func}; then
  last_command[${fnest_cur}]=" (F) $BASH_COMMAND"
  npipe[${#FUNCNAME[@]}]="${npipe[${fnest_cur}]}"
  fnest_cur="${#FUNCNAME[@]}"
  last_command[${fnest_cur}]="$BASH_COMMAND"
  no_print_flag=false
  is_func1=true
else
  last_command[${fnest_cur}]="$BASH_COMMAND"
fi
last_bg_pid=$!
last_pid=$BASHPID
starttime[${fnest_cur}]="${EPOCHREALTIME}"
}' DEBUG

{ echo ; } &
{ ( echo A & ); echo B; } &

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &

( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

trap 'echo got USR1; sleep .01' USR1
kill -USR1 $$
echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done
    
builtin trap - DEBUG EXIT RETURN

) {fd}>&2


:<<'EOF'
0
np: 1  1750180273.893317  1750180273.893765  (0.main)  (1460.2):  < pid: 1460 ( <-- 1458 )> is a BACKGROUND FORK

np: 1  1750180273.894127  1750180273.894161  (0.main)  (1458.1):  < 'echo 0' > is a NORMAL COMMAND
1
np: 1  1750180273.894258  1750180273.894305  (0.main)  (1460.2):  < 'echo' > is a NORMAL COMMAND
np: 1  1750180273.893317  1750180273.894172  (0.main)  (1462.3):  < pid: 1462 ( <-- 1458 )> is a BACKGROUND FORK
A
np: 1  1750180273.894458  1750180273.894805  (0.main)  (1463.2):  < pid: 1463 ( <-- 1458 )> is a BACKGROUND FORK
2
np: 1  1750180273.895140  1750180273.895171  (0.main)  (1463.2):  < 'echo 2' > is a NORMAL COMMAND
np: 1  1750180273.894718  1750180273.895024  (0.main)  (1462.3):  < 'echo A' > is a SIMPLE FORK
np: 1  1750180273.894458  1750180273.895599  (0.main)  (1458.1):  < 'echo 1' > is a NORMAL COMMAND
np: 1  1750180273.893317  1750180273.895702  (0.main)  (1461.2):  < pid: 1461 ( <-- 1458 )> is a BACKGROUND FORK
B
3
np: 1  1750180273.896148  1750180273.896189  (0.main)  (1461.2):  < 'echo B' > is a NORMAL COMMAND
np: 1  1750180273.895941  1750180273.896241  (0.main)  (1458.1):  < 'echo 3' > is a SIMPLE FORK
4
np: 1  1750180273.896584  1750180273.897080  (0.main)  (1467.2):  < pid: 1467 ( <-- 1458 )> is a BACKGROUND FORK
5
np: 1  1750180273.896584  1750180273.897182  (0.main)  (1468.2):  < pid: 1468 ( <-- 1458 )> is a SUBSHELL
np: 1  1750180273.897444  1750180273.897479  (0.main)  (1467.2):  < 'echo 5' > is a NORMAL COMMAND
6
np: 1  1750180273.897485  1750180273.897694  (0.main)  (1468.2):  < 'echo 6' > is a SIMPLE FORK
np: 1  1750180273.896584  1750180273.898418  (0.main)  (1470.2):  < pid: 1470 ( <-- 1458 )> is a BACKGROUND FORK
7
np: 1  1750180273.896584  1750180273.898515  (0.main)  (1471.2):  < pid: 1471 ( <-- 1458 )> is a SUBSHELL
8
np: 1  1750180273.898700  1750180273.898739  (0.main)  (1470.2):  < 'echo 7' > is a NORMAL COMMAND
np: 1  1750180273.898815  1750180273.898847  (0.main)  (1471.2):  < 'echo 8' > is a NORMAL COMMAND
np: 1  1750180273.896584  1750180273.899553  (0.main)  (1472.2):  < pid: 1472 ( <-- 1458 )> is a BACKGROUND FORK
np: 1  1750180273.896584  1750180273.899646  (0.main)  (1473.2):  < pid: 1473 ( <-- 1458 )> is a BACKGROUND FORK
9.1
np: 1  1750180273.896584  1750180273.899825  (0.main)  (1474.2):  < pid: 1474 ( <-- 1458 )> is a BACKGROUND FORK
np: 1  1750180273.900057  1750180273.900096  (0.main)  (1473.2):  < 'echo 9.1' > is a NORMAL COMMAND
np: 1  1750180273.896584  1750180273.899997  (0.main)  (1475.2):  < pid: 1475 ( <-- 1458 )> is a BACKGROUND FORK
9.1b
np: 1  1750180273.896584  1750180273.900101  (0.main)  (1476.2):  < pid: 1476 ( <-- 1458 )> is a BACKGROUND FORK
np: 1  1750180273.899979  1750180273.900239  (0.main)  (1472.2):  < 'echo 9' > is a SIMPLE FORK *
np: 1  1750180273.896584  1750180273.900317  (0.main)  (1458.1):  < 'echo 4' > is a SIMPLE FORK
11
np: 1  1750180273.896584  1750180273.900286  (0.main)  (1477.2):  < pid: 1477 ( <-- 1458 )> is a BACKGROUND FORK
9.999
np: 1  1750180273.900476  1750180273.900518  (0.main)  (1475.2):  < 'echo 9.1b' > is a NORMAL COMMAND
9
np: 1  1750180273.900295  1750180273.900598  (0.main)  (1474.2):  < 'echo 9.1a' > is a SIMPLE FORK *
9.2a
np: 1  1750180273.900661  1750180273.900703  (0.main)  (1458.1):  < 'echo 11' > is a NORMAL COMMAND
9.1a
9.2
9.1c
np: 1  1750180273.900934  1750180273.900985  (0.main)  (1474.2):  < 'echo 9.2a' > is a NORMAL COMMAND
np: 1  1750180273.900421  1750180273.900717  (0.main)  (1473.2):  < 'echo 9.2' > is a SIMPLE FORK
np: 1  1750180273.900544  1750180273.900776  (0.main)  (1476.2):  < 'echo 9.1c' > is a SIMPLE FORK *
np: 1  1750180273.900738  1750180273.901282  (0.main)  (1483.3):  < pid: 1483 ( <-- 1477 )> is a BACKGROUND FORK
9.2c
np: 1  1750180273.900840  1750180273.901462  (0.main)  (1475.2):  < 'echo 9.2b' > is a SIMPLE FORK
12
np: 1  1750180273.896584  1750180273.901689  (0.main)  (1479.2):  < pid: 1479 ( <-- 1458 )> is a BACKGROUND FORK
np: 1  1750180273.901436  1750180273.901775  (0.main)  (1476.2):  < 'echo 9.2c' > is a NORMAL COMMAND
np: 1  1750180273.901020  1750180273.901702  (0.main)  (1486.2):  < pid: 1486 ( <-- 1458 )> is a BACKGROUND FORK
13
np: 1  1750180273.901693  1750180273.901931  (0.main)  (1483.3):  < 'echo 9.3' > is a SIMPLE FORK
np: 1  1750180273.901020  1750180273.901819  (0.main)  (1487.2):  < pid: 1487 ( <-- 1458 )> is a BACKGROUND FORK
9.4
14
9.3
np: 1  1750180273.902143  1750180273.902254  (0.main)  (1486.2):  < 'echo 13' > is a NORMAL COMMAND
np: 1  1750180273.902288  1750180273.902334  (0.main)  (1487.2):  < 'echo 14' > is a NORMAL COMMAND
10
np: 1  1750180273.902278  1750180273.902318  (0.main)  (1483.3):  < 'echo 9.4' > is a NORMAL COMMAND
np: 1  1750180273.902081  1750180273.902396  (0.main)  (1479.2):  < 'echo 10' > is a SIMPLE FORK
9.2b
np: 1  1750180273.901020  1750180273.902805  (0.main)  (1458.1):  < 'echo 12' > is a SIMPLE FORK
np: 1  1750180273.900738  1750180273.902912  (0.main)  (1477.2):  < 'echo 9.999' > is a NORMAL COMMAND
9.5
np: 1  1750180273.903278  1750180273.903321  (0.main)  (1477.2):  < 'echo 9.5' > is a NORMAL COMMAND
np: 1  1750180273.903600  1750180273.903634  (2.ff)  (1458.1):  < 'ff 15' > is a FUNCTION (C)
15
np: 1  1750180273.903943  1750180273.903976  (2.ff)  (1458.1):  < 'echo "${*}"' > is a NORMAL COMMAND
np: 1  1750180273.903208  1750180273.904870  (0.main)  (1458.1):  < 'ff 15' > is a FUNCTION (P)
np: 1  1750180273.905298  1750180273.905319  (2.gg)  (1458.1):  < 'gg 16' > is a FUNCTION (C)
16
np: 1  1750180273.905597  1750180273.905634  (2.gg)  (1458.1):  < 'echo "$*"' > is a NORMAL COMMAND
np: 1  1750180273.906263  1750180273.906295  (3.ff)  (1458.1):  < 'ff "$@"' > is a FUNCTION (C)
16
np: 1  1750180273.906497  1750180273.906539  (3.ff)  (1458.1):  < 'echo "${*}"' > is a NORMAL COMMAND
np: 1  1750180273.905927  1750180273.907563  (2.gg)  (1458.1):  < 'ff "$@"' > is a FUNCTION (P)
np: 1  1750180273.905074  1750180273.908810  (0.main)  (1490.2):  < pid: 1490 ( <-- 1458 )> is a BACKGROUND FORK
a
np: 1  1750180273.905074  1750180273.909210  (0.main)  (1492.2):  < pid: 1492 ( <-- 1458 )> is a SUBSHELL
np: 1  1750180273.905074  1750180273.909237  (0.main)  (1493.3):  < pid: 1493 ( <-- 1458 )> is a BACKGROUND FORK
b
np: 1  1750180273.909197  1750180273.909477  (0.main)  (1490.2):  < 'echo a' > is a SIMPLE FORK
A2
np: 1  1750180273.905074  1750180273.909501  (0.main)  (1495.4):  < pid: 1495 ( <-- 1458 )> is a SUBSHELL
np: 1  1750180273.909719  1750180273.909772  (0.main)  (1493.3):  < 'echo b' > is a NORMAL COMMAND
np: 1  1750180273.909616  1750180273.909883  (0.main)  (1492.2):  < 'echo A2' > is a SIMPLE FORK
A5
A1
np: 1  1750180273.910247  1750180273.910296  (0.main)  (1492.2):  < 'echo A1' > is a NORMAL COMMAND
np: 1  1750180273.909979  1750180273.910269  (0.main)  (1495.4):  < 'echo A5' > is a SIMPLE FORK
np: 1  1750180273.905074  1750180273.910726  (0.main)  (1458.1):  < 'gg 16' > is a FUNCTION (P)
np: 1  1750180273.905074  1750180273.911161  (0.main)  (1494.3):  < pid: 1494 ( <-- 1458 )> is a BACKGROUND FORK
A3
np: 1  1750180273.911046  1750180273.911310  (0.main)  (1458.1):  < $'cat <<EOF\nfoo\nbar\nbaz\nEOF\n' > is a NORMAL COMMAND
np: 1  1750180273.905074  1750180273.911159  (0.main)  (1499.4):  < pid: 1499 ( <-- 1458 )> is a BACKGROUND FORK
A4
np: 1  1750180273.911549  1750180273.911584  (0.main)  (1494.3):  < 'echo A3' > is a NORMAL COMMAND
np: 1  1750180273.911636  1750180273.911686  (0.main)  (1499.4):  < 'echo A4' > is a NORMAL COMMAND
np: 1  1750180273.911585  1750180273.911812  (0.main)  (1458.1):  < 'grep foo' > is a NORMAL COMMAND
np: 1  1750180273.912124  1750180273.912393  (0.main)  (1458.1):  < 'sed '\''s/o/O/g'\''' > is a NORMAL COMMAND
1
np: 4  1750180273.912624  1750180273.913943  (0.main)  (1458.1):  < 'wc -l' > is a NORMAL COMMAND
np: 4  1750180273.914328  1750180273.914724  (0.main)  (1504.2):  < pid: 1504 ( <-- 1458 )> is a SUBSHELL
today is 2025-06-17
np: 1  1750180273.914328  1750180273.915954  (0.main)  (1458.1):  < 'echo "today is $(date +%Y-%m-%d)"' > is a NORMAL COMMAND
np: 1  1750180273.916405  1750180273.916982  (0.main)  (1505.2):  < pid: 1505 ( <-- 1458 )> is a SUBSHELL
np: 1  1750180273.916405  1750180273.917044  (0.main)  (1506.3):  < pid: 1506 ( <-- 1458 )> is a SUBSHELL
np: 1  1750180273.917546  1750180273.917636  (0.main)  (1506.3):  < 'echo nested' > is a NORMAL COMMAND
np: 1  1750180273.917904  1750180273.917973  (0.main)  (1506.3):  < 'echo subshell' > is a NORMAL COMMAND
np: 2  1750180273.917453  1750180273.918990  (0.main)  (1505.2):  < 'grep sub' > is a NORMAL COMMAND
np: 1  1750180273.916405  1750180273.919724  (0.main)  (1458.1):  < 'x=$( ( echo nested; echo subshell ) | grep sub)' > is a NORMAL COMMAND
np: 1  1750180273.920093  1750180273.920450  (0.main)  (1508.2):  < pid: 1508 ( <-- 1458 )> is a SUBSHELL
np: 1  1750180273.920093  1750180273.920690  (0.main)  (1509.2):  < pid: 1509 ( <-- 1458 )> is a SUBSHELL
1,22c1,2
< bin
< boot
< dev
< etc
< home
< lib
< lib32
< lib64
< lib.usr-is-merged
< media
< mnt
< opt
< proc
< root
< run
< sbin
< script
< srv
< sys
< tmp
< usr
< var
---
> hsperfdata_root
> hsperfdata_runner29
np: 1  1750180273.920093  1750180273.923606  (0.main)  (1458.1):  < 'diff <(ls /) <(ls /tmp)' > is a SIMPLE FORK
np: 1  1750180273.923971  1750180273.924426  (0.main)  (1511.2):  < pid: 1511 ( <-- 1458 )> is a SUBSHELL
np: 1  1750180273.923971  1750180273.925944  (0.main)  (1458.1):  < 'grep pattern <(sed '\''s/^/>>/'\'' > /dev/null)' > is a SIMPLE FORK
np: 1  1750180273.923971  1750180273.926023  (0.main)  (1513.2):  < pid: 1513 ( <-- 1458 )> is a BACKGROUND FORK
np: 1  1750180273.926707  1750180273.926751  (0.main)  (1513.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
np: 1  1750180273.927025  1750180273.927185  (0.main)  (1513.2):  < 'echo "$i"' > is a NORMAL COMMAND
np: 1  1750180273.926396  1750180273.927099  (0.main)  (1458.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 1
np: 1  1750180273.927629  1750180273.927678  (0.main)  (1458.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
np: 1  1750180273.927603  1750180273.938856  (0.main)  (1513.2):  < 'sleep .01' > is a NORMAL COMMAND
np: 1  1750180273.939137  1750180273.939163  (0.main)  (1513.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
np: 1  1750180273.939420  1750180273.939464  (0.main)  (1513.2):  < 'echo "$i"' > is a NORMAL COMMAND
np: 1  1750180273.928023  1750180273.939499  (0.main)  (1458.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 2
np: 1  1750180273.939861  1750180273.939921  (0.main)  (1458.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
np: 1  1750180273.939722  1750180273.950681  (0.main)  (1513.2):  < 'sleep .01' > is a NORMAL COMMAND
np: 1  1750180273.950974  1750180273.951015  (0.main)  (1513.2):  < 'for i in {1..3}' > is a NORMAL COMMAND
np: 1  1750180273.951270  1750180273.951313  (0.main)  (1513.2):  < 'echo "$i"' > is a NORMAL COMMAND
np: 1  1750180273.940284  1750180273.951347  (0.main)  (1458.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 3
np: 1  1750180273.951690  1750180273.951738  (0.main)  (1458.1):  < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
np: 1  1750180273.951653  1750180273.962673  (0.main)  (1513.2):  < 'sleep .01' > is a NORMAL COMMAND
np: 1  1750180273.952098  1750180273.963202  (0.main)  (1458.1):  < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
np: 1  1750180273.963482  1750180273.963511  (0.main)  (1458.1):  < 'let "x = 5 + 6"' > is a NORMAL COMMAND
np: 1  1750180273.963727  1750180273.963771  (0.main)  (1458.1):  < 'arr=(one two three)' > is a NORMAL COMMAND
one two three
np: 1  1750180273.964036  1750180273.964078  (0.main)  (1458.1):  < 'echo ${arr[@]}' > is a NORMAL COMMAND
np: 1  1750180273.964383  1750180273.964422  (0.main)  (1458.1):  < '((i=0))' > is a NORMAL COMMAND
np: 1  1750180273.964680  1750180273.964704  (0.main)  (1458.1):  < '((i<3))' > is a NORMAL COMMAND
0
np: 1  1750180273.964963  1750180273.965012  (0.main)  (1458.1):  < 'echo "$i"' > is a NORMAL COMMAND
np: 1  1750180273.965330  1750180273.965368  (0.main)  (1458.1):  < '((i++))' > is a NORMAL COMMAND
np: 1  1750180273.965631  1750180273.965656  (0.main)  (1458.1):  < '((i<3))' > is a NORMAL COMMAND
1
np: 1  1750180273.965856  1750180273.965885  (0.main)  (1458.1):  < 'echo "$i"' > is a NORMAL COMMAND
np: 1  1750180273.966175  1750180273.966200  (0.main)  (1458.1):  < '((i++))' > is a NORMAL COMMAND
np: 1  1750180273.966491  1750180273.966528  (0.main)  (1458.1):  < '((i<3))' > is a NORMAL COMMAND
2
np: 1  1750180273.966777  1750180273.966806  (0.main)  (1458.1):  < 'echo "$i"' > is a NORMAL COMMAND
np: 1  1750180273.967008  1750180273.967040  (0.main)  (1458.1):  < '((i++))' > is a NORMAL COMMAND
np: 1  1750180273.967362  1750180273.967399  (0.main)  (1458.1):  < '((i<3))' > is a NORMAL COMMAND
np: 1  1750180273.967703  1750180273.967728  (0.main)  (1458.1):  < 'cmd="echo inside-eval"' > is a NORMAL COMMAND
np: 1  1750180273.968006  1750180273.968047  (0.main)  (1458.1):  < 'eval "$cmd"' > is a NORMAL COMMAND
inside-eval
np: 1  1750180273.968381  1750180273.968413  (0.main)  (1458.1):  < 'echo inside-eval' > is a NORMAL COMMAND
np: 1  1750180273.968710  1750180273.968757  (0.main)  (1458.1):  < 'eval "eval \"$cmd\""' > is a NORMAL COMMAND
np: 1  1750180273.968997  1750180273.969029  (0.main)  (1458.1):  < 'eval "echo inside-eval"' > is a NORMAL COMMAND
inside-eval

EOF

##################################################################################

(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=()
subshell_pid=''
next_is_simple_fork_flag=false
this_is_simple_fork_flag=false
fnest=(${#FUNCNAME[@]})
fnest_cur=${#FUNCNAME[@]}
last_command[${fnest_cur}]=''

trap() {
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap ':' EXIT ;;
            RETURN)  builtin trap  'skip_debug=true
unset "fnest[-1]" "last_command[-1]"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
}

export -f trap


skip_debug=false
no_print_flag=false
is_func1=false

builtin trap ':' EXIT 
builtin trap 'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

builtin trap 'npipe0=${#PIPESTATUS[@]}
[[ "${BASH_COMMAND}" == trap* ]] && {
  skip_debug=true
  (( fnest_cur == ${#FUNCNAME[@]} )) && {
    fnest_cur=${#FUNCNAME[@]}
    fnest+=("${#FUNCNAME[@]}")
    last_command+=('')
  }
}
${skip_debug} || {
npipe=$npipe0
is_bg=false
is_subshell=false
is_func=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  if (( last_bg_pid == $! )); then
    (( fnest_cur >= ${#FUNCNAME[@]} )) || {
      no_print_flag=true
      is_func=true
      fnest+=("${#FUNCNAME[@]}")
    }
  else
    is_bg=true
  fi
else
  is_subshell=true
  subshell_pid=$BASHPID 
  builtin trap '"'"':'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == parent_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
  cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif [[ "${last_command[${fnest_cur}]}" == " (F) "* ]]; then
  cmd_type="FUNCTION (P)"
  last_command[${fnest_cur}]="${last_command[${fnest_cur}]# (F) }"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
elif ${is_func1}; then
  cmd_type="FUNCTION (C)"
  is_func1=false
else
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  ${no_print_flag} || printf '"'"'pp: %s  pt: %s  cp: %s  ct: %s  lbp: %s  bp: %s  BP: %s  BS: %s  lBS: %s  F: %s  lF: %s (%s)  PP: %s  np: %s  (%s): < pid: %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" ${#FUNCNAME[@]} $fnest_cur ${FUNCNAME[0]:-main} "${PPID:-\?}" $npipe  "$last_pid" "$BASHPID" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ ${last_command[${fnest_cur}]} ]]; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  ${no_print_flag} || printf '"'"'pp: %s  pt: %s  cp: %s  ct: %s  lbp: %s  bp: %s  BP: %s  BS: %s  lBS: %s  F: %s  lF: %s (%s)  PP: %s  np: %s  (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" ${#FUNCNAME[@]} $fnest_cur ${FUNCNAME[0]:-main} "${PPID:-\?}" $npipe  "$BASHPID" "${last_command[${fnest_cur}]@Q}" "$cmd_type"
fi >&$fd
if ${is_func}; then
  last_command[${fnest_cur}]=" (F) $BASH_COMMAND"
  fnest_cur="${#FUNCNAME[@]}"
  last_command[${fnest_cur}]="$BASH_COMMAND"
  no_print_flag=false
  is_func1=true
else
  last_command[${fnest_cur}]="$BASH_COMMAND"
fi
last_bg_pid=$!
last_pid=$BASHPID
}' DEBUG

{ echo ; } &
{ ( echo A & ); echo B; } &

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &


( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

trap 'echo got USR1; sleep .01' USR1
kill -USR1 $$
echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done
    
builtin trap - DEBUG EXIT RETURN

) {fd}>&2


:<<'EOF'

0
pp: 9277  pt: 9277  cp: 9283  ct: 9277  lbp: 9282  bp: 9282  BP: 9283  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9283 > is a BACKGROUND FORK

pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9284  bp: 9284  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'echo 0' > is a NORMAL COMMAND
1
pp: 9283  pt: 9277  cp: 9283  ct: 9277  lbp: 9282  bp: 9282  BP: 9283  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9283): < 'echo' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9284  ct: 9277  lbp: 9282  bp: 9283  BP: 9285  BS: 3  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9285 > is a BACKGROUND FORK
A
pp: 9277  pt: 9277  cp: 9286  ct: 9284  lbp: 9284  bp: 9284  BP: 9286  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9286 > is a BACKGROUND FORK
2
pp: 9286  pt: 9284  cp: 9286  ct: 9284  lbp: 9284  bp: 9284  BP: 9286  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9286): < 'echo 2' > is a NORMAL COMMAND
pp: 9284  pt: 9277  cp: 9284  ct: 9277  lbp: 9283  bp: 9287  BP: 9285  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9285): < 'echo A' > is a SIMPLE FORK
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9284  bp: 9284  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'echo 1' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9284  ct: 9277  lbp: 9282  bp: 9283  BP: 9284  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9284 > is a BACKGROUND FORK
B
3
pp: 9284  pt: 9277  cp: 9284  ct: 9277  lbp: 9283  bp: 9283  BP: 9284  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9284): < 'echo B' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9284  bp: 9288  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'echo 3' > is a SIMPLE FORK
4
pp: 9277  pt: 9277  cp: 9290  ct: 9291  lbp: 9288  bp: 9289  BP: 9290  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9290 > is a BACKGROUND FORK
5
pp: 9277  pt: 9277  cp: 9291  ct: 9291  lbp: 9288  bp: 9290  BP: 9291  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9291 > is a SUBSHELL
pp: 9290  pt: 9291  cp: 9290  ct: 9291  lbp: 9289  bp: 9289  BP: 9290  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9290): < 'echo 5' > is a NORMAL COMMAND
6
pp: 9291  pt: 9291  cp: 9291  ct: 9291  lbp: 9290  bp: 9292  BP: 9291  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9291): < 'echo 6' > is a SIMPLE FORK
pp: 9277  pt: 9277  cp: 9293  ct: 9294  lbp: 9288  bp: 9290  BP: 9293  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9293 > is a BACKGROUND FORK
7
pp: 9277  pt: 9277  cp: 9294  ct: 9294  lbp: 9288  bp: 9293  BP: 9294  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9294 > is a SUBSHELL
8
pp: 9293  pt: 9294  cp: 9293  ct: 9294  lbp: 9290  bp: 9290  BP: 9293  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9293): < 'echo 7' > is a NORMAL COMMAND
pp: 9294  pt: 9294  cp: 9294  ct: 9294  lbp: 9293  bp: 9293  BP: 9294  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9294): < 'echo 8' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9295  ct: 9277  lbp: 9288  bp: 9293  BP: 9295  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9295 > is a BACKGROUND FORK
pp: 9277  pt: 9277  cp: 9296  ct: 9277  lbp: 9288  bp: 9295  BP: 9296  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9296 > is a BACKGROUND FORK
9.1
9
pp: 9277  pt: 9277  cp: 9297  ct: 9277  lbp: 9288  bp: 9296  BP: 9297  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9297 > is a BACKGROUND FORK
pp: 9296  pt: 9277  cp: 9296  ct: 9277  lbp: 9295  bp: 9295  BP: 9296  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9296): < 'echo 9.1' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9298  ct: 9277  lbp: 9288  bp: 9297  BP: 9298  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9298 > is a BACKGROUND FORK
9.1b
pp: 9295  pt: 9277  cp: 9295  ct: 9277  lbp: 9293  bp: 9300  BP: 9295  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9295): < 'echo 9' > is a SIMPLE FORK *
9.1a
pp: 9298  pt: 9277  cp: 9298  ct: 9277  lbp: 9297  bp: 9297  BP: 9298  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9298): < 'echo 9.1b' > is a NORMAL COMMAND
9.2
pp: 9297  pt: 9277  cp: 9297  ct: 9277  lbp: 9296  bp: 9303  BP: 9297  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9297): < 'echo 9.1a' > is a SIMPLE FORK *
9.2a
pp: 9296  pt: 9277  cp: 9296  ct: 9277  lbp: 9295  bp: 9304  BP: 9296  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9296): < 'echo 9.2' > is a SIMPLE FORK
pp: 9277  pt: 9277  cp: 9302  ct: 9277  lbp: 9288  bp: 9301  BP: 9302  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9302 > is a BACKGROUND FORK
pp: 9297  pt: 9277  cp: 9297  ct: 9277  lbp: 9303  bp: 9303  BP: 9297  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9297): < 'echo 9.2a' > is a NORMAL COMMAND
pp: 9298  pt: 9277  cp: 9298  ct: 9277  lbp: 9297  bp: 9305  BP: 9298  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9298): < 'echo 9.2b' > is a SIMPLE FORK
pp: 9277  pt: 9277  cp: 9299  ct: 9277  lbp: 9288  bp: 9298  BP: 9299  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9299 > is a BACKGROUND FORK
pp: 9277  pt: 9277  cp: 9301  ct: 9277  lbp: 9288  bp: 9299  BP: 9301  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9301 > is a BACKGROUND FORK
10
9.999
9.1c
9.2b
pp: 9302  pt: 9277  cp: 9302  ct: 9277  lbp: 9301  bp: 9306  BP: 9302  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9302): < 'echo 10' > is a SIMPLE FORK *
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9288  bp: 9302  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'echo 4' > is a SIMPLE FORK
11
pp: 9299  pt: 9277  cp: 9299  ct: 9277  lbp: 9298  bp: 9307  BP: 9299  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9299): < 'echo 9.1c' > is a SIMPLE FORK *
9.2c
pp: 9301  pt: 9277  cp: 9301  ct: 9277  lbp: 9299  bp: 9299  BP: 9308  BS: 3  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9301): < pid: 9308 > is a SUBSHELL
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9302  bp: 9302  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'echo 11' > is a NORMAL COMMAND
pp: 9299  pt: 9277  cp: 9299  ct: 9277  lbp: 9307  bp: 9307  BP: 9299  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9299): < 'echo 9.2c' > is a NORMAL COMMAND
9.3
12
pp: 9301  pt: 9277  cp: 9301  ct: 9277  lbp: 9299  bp: 9309  BP: 9308  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9308): < 'echo 9.3' > is a SIMPLE FORK
9.4
pp: 9301  pt: 9277  cp: 9301  ct: 9277  lbp: 9309  bp: 9309  BP: 9308  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9308): < 'echo 9.4' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9311  ct: 9312  lbp: 9302  bp: 9310  BP: 9311  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9311 > is a BACKGROUND FORK
13
pp: 9311  pt: 9312  cp: 9311  ct: 9312  lbp: 9310  bp: 9310  BP: 9311  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9311): < 'echo 13' > is a NORMAL COMMAND
pp: 9301  pt: 9277  cp: 9301  ct: 9277  lbp: 9299  bp: 9299  BP: 9301  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9301): < 'echo 9.999' > is a NORMAL COMMAND
9.5
pp: 9277  pt: 9277  cp: 9312  ct: 9312  lbp: 9302  bp: 9311  BP: 9312  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9312 > is a SUBSHELL
14
pp: 9301  pt: 9277  cp: 9301  ct: 9277  lbp: 9299  bp: 9299  BP: 9301  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9301): < 'echo 9.5' > is a NORMAL COMMAND
pp: 9312  pt: 9312  cp: 9312  ct: 9312  lbp: 9311  bp: 9311  BP: 9312  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9312): < 'echo 14' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9302  bp: 9311  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'echo 12' > is a SIMPLE FORK
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9311  bp: 9311  BP: 9281  BS: 1  lBS: 1  F: 2  lF: 2 (ff)  PP: 9276  np: 1  (9281): < 'ff 15' > is a FUNCTION (C)
15
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9311  bp: 9311  BP: 9281  BS: 1  lBS: 1  F: 2  lF: 2 (ff)  PP: 9276  np: 1  (9281): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9311  bp: 9311  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'ff 15' > is a FUNCTION (P)
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9311  bp: 9311  BP: 9281  BS: 1  lBS: 1  F: 2  lF: 2 (gg)  PP: 9276  np: 1  (9281): < 'gg 16' > is a FUNCTION (C)
16
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9311  bp: 9311  BP: 9281  BS: 1  lBS: 1  F: 2  lF: 2 (gg)  PP: 9276  np: 1  (9281): < 'echo "$*"' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9311  bp: 9311  BP: 9281  BS: 1  lBS: 1  F: 3  lF: 3 (ff)  PP: 9276  np: 1  (9281): < 'ff "$@"' > is a FUNCTION (C)
16
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9311  bp: 9311  BP: 9281  BS: 1  lBS: 1  F: 3  lF: 3 (ff)  PP: 9276  np: 1  (9281): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9311  bp: 9311  BP: 9281  BS: 1  lBS: 1  F: 2  lF: 2 (gg)  PP: 9276  np: 1  (9281): < 'ff "$@"' > is a FUNCTION (P)
pp: 9277  pt: 9277  cp: 9313  ct: 9315  lbp: 9311  bp: 9311  BP: 9313  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9313 > is a BACKGROUND FORK
a
pp: 9277  pt: 9277  cp: 9314  ct: 9315  lbp: 9311  bp: 9313  BP: 9316  BS: 3  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9316 > is a BACKGROUND FORK
pp: 9277  pt: 9277  cp: 9315  ct: 9315  lbp: 9311  bp: 9317  BP: 9315  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9315 > is a SUBSHELL
b
pp: 9313  pt: 9315  cp: 9313  ct: 9315  lbp: 9311  bp: 9318  BP: 9313  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9313): < 'echo a' > is a SIMPLE FORK
A2
pp: 9314  pt: 9315  cp: 9314  ct: 9315  lbp: 9313  bp: 9313  BP: 9316  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9316): < 'echo b' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9315  ct: 9315  lbp: 9311  bp: 9314  BP: 9319  BS: 4  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9319 > is a SUBSHELL
pp: 9315  pt: 9315  cp: 9315  ct: 9315  lbp: 9317  bp: 9320  BP: 9315  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9315): < 'echo A2' > is a SIMPLE FORK
A1
pp: 9315  pt: 9315  cp: 9315  ct: 9315  lbp: 9320  bp: 9320  BP: 9315  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9315): < 'echo A1' > is a NORMAL COMMAND
A5
pp: 9315  pt: 9315  cp: 9315  ct: 9315  lbp: 9314  bp: 9321  BP: 9319  BS: 4  lBS: 4  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9319): < 'echo A5' > is a SIMPLE FORK
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9311  bp: 9314  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'gg 16' > is a FUNCTION (P)
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < $'cat <<EOF\nfoo\nbar\nbaz\nEOF\n' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9315  ct: 9322  lbp: 9311  bp: 9314  BP: 9323  BS: 4  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9323 > is a BACKGROUND FORK
A4
pp: 9277  pt: 9277  cp: 9315  ct: 9322  lbp: 9311  bp: 9323  BP: 9317  BS: 3  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9317 > is a BACKGROUND FORK
A3
pp: 9315  pt: 9322  cp: 9315  ct: 9322  lbp: 9314  bp: 9314  BP: 9323  BS: 4  lBS: 4  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9323): < 'echo A4' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'grep foo' > is a NORMAL COMMAND
pp: 9315  pt: 9322  cp: 9315  ct: 9322  lbp: 9323  bp: 9323  BP: 9317  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9317): < 'echo A3' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'sed '\''s/o/O/g'\''' > is a NORMAL COMMAND
1
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 4  (9281): < 'wc -l' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9327  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 4  (9281): < pid: 9327 > is a SUBSHELL
today is 2025-06-16
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'echo "today is $(date +%Y-%m-%d)"' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9328  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9328 > is a SUBSHELL
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9329  BS: 3  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9329 > is a SUBSHELL
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9329  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9329): < 'echo nested' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9329  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9329): < 'echo subshell' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9328  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 2  (9328): < 'grep sub' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'x=$( ( echo nested; echo subshell ) | grep sub)' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9314  BP: 9331  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9331 > is a SUBSHELL
pp: 9277  pt: 9277  cp: 9277  ct: 9333  lbp: 9314  bp: 9331  BP: 9332  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9332 > is a SUBSHELL
1,22c1
< bin
< boot
< dev
< etc
< home
< lib
< lib32
< lib64
< lib.usr-is-merged
< media
< mnt
< opt
< proc
< root
< run
< sbin
< script
< srv
< sys
< tmp
< usr
< var
---
> hsperfdata_runner98
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9314  bp: 9332  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'diff <(ls /) <(ls /tmp)' > is a SIMPLE FORK
pp: 9277  pt: 9277  cp: 9277  ct: 9335  lbp: 9332  bp: 9332  BP: 9334  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9334 > is a SUBSHELL
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9332  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'grep pattern <(sed '\''s/^/>>/'\'' > /dev/null)' > is a SIMPLE FORK
pp: 9277  pt: 9277  cp: 9336  ct: 9277  lbp: 9332  bp: 9334  BP: 9336  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < pid: 9336 > is a BACKGROUND FORK
pp: 9336  pt: 9277  cp: 9336  ct: 9277  lbp: 9334  bp: 9334  BP: 9336  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9336): < 'for i in {1..3}' > is a NORMAL COMMAND
pp: 9336  pt: 9277  cp: 9336  ct: 9277  lbp: 9334  bp: 9334  BP: 9336  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9336): < 'echo "$i"' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 1
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
pp: 9336  pt: 9277  cp: 9336  ct: 9277  lbp: 9334  bp: 9334  BP: 9336  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9336): < 'sleep .01' > is a NORMAL COMMAND
pp: 9336  pt: 9277  cp: 9336  ct: 9277  lbp: 9334  bp: 9334  BP: 9336  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9336): < 'for i in {1..3}' > is a NORMAL COMMAND
pp: 9336  pt: 9277  cp: 9336  ct: 9277  lbp: 9334  bp: 9334  BP: 9336  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9336): < 'echo "$i"' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 2
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
pp: 9336  pt: 9277  cp: 9336  ct: 9277  lbp: 9334  bp: 9334  BP: 9336  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9336): < 'sleep .01' > is a NORMAL COMMAND
pp: 9336  pt: 9277  cp: 9336  ct: 9277  lbp: 9334  bp: 9334  BP: 9336  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9336): < 'for i in {1..3}' > is a NORMAL COMMAND
pp: 9336  pt: 9277  cp: 9336  ct: 9277  lbp: 9334  bp: 9334  BP: 9336  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9336): < 'echo "$i"' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 3
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
pp: 9336  pt: 9277  cp: 9336  ct: 9277  lbp: 9334  bp: 9334  BP: 9336  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9336): < 'sleep .01' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'let "x = 5 + 6"' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'arr=(one two three)' > is a NORMAL COMMAND
one two three
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'echo ${arr[@]}' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < '((i=0))' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < '((i<3))' > is a NORMAL COMMAND
0
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'echo "$i"' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < '((i++))' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < '((i<3))' > is a NORMAL COMMAND
1
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'echo "$i"' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < '((i++))' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < '((i<3))' > is a NORMAL COMMAND
2
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'echo "$i"' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < '((i++))' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < '((i<3))' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'cmd="echo inside-eval"' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'eval "$cmd"' > is a NORMAL COMMAND
inside-eval
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'echo inside-eval' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'eval "eval \"$cmd\""' > is a NORMAL COMMAND
pp: 9277  pt: 9277  cp: 9277  ct: 9277  lbp: 9336  bp: 9336  BP: 9281  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 9276  np: 1  (9281): < 'eval "echo inside-eval"' > is a NORMAL COMMAND
inside-eval

EOF

#######################################################################



(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=()
subshell_pid=''
next_is_simple_fork_flag=false
this_is_simple_fork_flag=false
fnest=(${#FUNCNAME[@]})
fnest_cur=${#FUNCNAME[@]}
last_command[${fnest_cur}]=''

trap() {
    skip_debug=true
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap ':' EXIT ;;
            RETURN)  builtin trap  'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
        skip_debug=false
}

export -f trap


skip_debug=false
no_print_flag=true
is_func1=false

builtin trap ':' EXIT 
builtin trap 'skip_debug=true
unset "fnest[-1]" "last_command[${fnest_cur}]"
fnest_cur="${fnest[-1]}"
skip_debug=false' RETURN

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

builtin trap 'npipe0=${#PIPESTATUS[@]}
${skip_debug} || [[ "${BASH_COMMAND}" == trap* ]] || {
npipe=$npipe0
is_bg=false
is_subshell=false
is_func=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  if (( last_bg_pid == $! )); then
    (( fnest_cur >= ${#FUNCNAME[@]} )) || {
      no_print_flag=true
      is_func=true
      fnest+=("${#FUNCNAME[@]}")
    }
  else
    is_bg=true
  fi
else
  is_subshell=true
  subshell_pid=$BASHPID 
  builtin trap '"'"':'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == parent_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
  cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
elif [[ "${last_command[${fnest_cur}]}" == " (F) "* ]]; then
  cmd_type="FUNCTION (P)"
  last_command[${fnest_cur}]="${last_command[${fnest_cur}]# (F) }"
elif ${is_func1}; then
  cmd_type="FUNCTION (C)"
  is_func1=false
else
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  ${no_print_flag} || printf '"'"'pp: %s  pt: %s  cp: %s  ct: %s  lbp: %s  bp: %s  BP: %s  BS: %s  lBS: %s  F: %s  lF: %s (%s)  PP: %s  np: %s  (%s): < pid: %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" ${#FUNCNAME[@]} $fnest_cur ${FUNCNAME[0]:-main} "${PPID:-\?}" $npipe  "$last_pid" "$BASHPID" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ ${last_command[${fnest_cur}]} ]]; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  ${no_print_flag} || printf '"'"'pp: %s  pt: %s  cp: %s  ct: %s  lbp: %s  bp: %s  BP: %s  BS: %s  lBS: %s  F: %s  lF: %s (%s)  PP: %s  np: %s  (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" ${#FUNCNAME[@]} $fnest_cur ${FUNCNAME[0]:-main} "${PPID:-\?}" $npipe  "$BASHPID" "${last_command[${fnest_cur}]@Q}" "$cmd_type"
fi >&$fd
if ${is_func}; then
  last_command[${fnest_cur}]=" (F) $BASH_COMMAND"
  fnest_cur="${#FUNCNAME[@]}"
  last_command[${fnest_cur}]="$BASH_COMMAND"
  no_print_flag=false
  is_func1=true
else
  last_command[${fnest_cur}]="$BASH_COMMAND"
fi
last_bg_pid=$!
last_pid=$BASHPID
}' DEBUG

no_print_flag=false

{ echo ; } &
{ ( echo A & ); echo B; } &

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &


( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

trap 'echo got USR1; sleep .01' USR1
kill -USR1 $$
echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done

:
    
trap - DEBUG EXIT RETURN

) {fd}>&2

:<<'EOF'

pp: 3224  pt: 3224  cp: 3230  ct: 3224  lbp: 3229  bp: 3229  BP: 3230  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3230 > is a BACKGROUND FORK
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3229  bp: 3231  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'no_print_flag=false' > is a SIMPLE FORK

0
pp: 3230  pt: 3224  cp: 3230  ct: 3224  lbp: 3229  bp: 3229  BP: 3230  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3230): < 'echo' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3231  bp: 3231  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'echo 0' > is a NORMAL COMMAND
1
pp: 3224  pt: 3224  cp: 3231  ct: 3224  lbp: 3229  bp: 3230  BP: 3232  BS: 3  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3232 > is a BACKGROUND FORK
A
pp: 3224  pt: 3224  cp: 3233  ct: 3231  lbp: 3231  bp: 3231  BP: 3233  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3233 > is a BACKGROUND FORK
pp: 3231  pt: 3224  cp: 3231  ct: 3224  lbp: 3230  bp: 3234  BP: 3232  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3232): < 'echo A' > is a SIMPLE FORK
2
pp: 3233  pt: 3231  cp: 3233  ct: 3231  lbp: 3231  bp: 3231  BP: 3233  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3233): < 'echo 2' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3231  ct: 3224  lbp: 3229  bp: 3230  BP: 3231  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3231 > is a BACKGROUND FORK
B
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3231  bp: 3231  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'echo 1' > is a NORMAL COMMAND
pp: 3231  pt: 3224  cp: 3231  ct: 3224  lbp: 3230  bp: 3230  BP: 3231  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3231): < 'echo B' > is a NORMAL COMMAND
3
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3231  bp: 3235  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'echo 3' > is a SIMPLE FORK
4
pp: 3224  pt: 3224  cp: 3237  ct: 3238  lbp: 3235  bp: 3236  BP: 3237  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3237 > is a BACKGROUND FORK
5
pp: 3237  pt: 3238  cp: 3237  ct: 3238  lbp: 3236  bp: 3236  BP: 3237  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3237): < 'echo 5' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3238  ct: 3238  lbp: 3235  bp: 3237  BP: 3238  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3238 > is a SUBSHELL
6
pp: 3238  pt: 3238  cp: 3238  ct: 3238  lbp: 3237  bp: 3239  BP: 3238  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3238): < 'echo 6' > is a SIMPLE FORK
pp: 3224  pt: 3224  cp: 3240  ct: 3241  lbp: 3235  bp: 3237  BP: 3240  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3240 > is a BACKGROUND FORK
pp: 3224  pt: 3224  cp: 3241  ct: 3241  lbp: 3235  bp: 3240  BP: 3241  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3241 > is a SUBSHELL
7
8
pp: 3240  pt: 3241  cp: 3240  ct: 3241  lbp: 3237  bp: 3237  BP: 3240  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3240): < 'echo 7' > is a NORMAL COMMAND
pp: 3241  pt: 3241  cp: 3241  ct: 3241  lbp: 3240  bp: 3240  BP: 3241  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3241): < 'echo 8' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3242  ct: 3224  lbp: 3235  bp: 3240  BP: 3242  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3242 > is a BACKGROUND FORK
pp: 3224  pt: 3224  cp: 3243  ct: 3224  lbp: 3235  bp: 3242  BP: 3243  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3243 > is a BACKGROUND FORK
9.1
pp: 3224  pt: 3224  cp: 3244  ct: 3224  lbp: 3235  bp: 3243  BP: 3244  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3244 > is a BACKGROUND FORK
pp: 3243  pt: 3224  cp: 3243  ct: 3224  lbp: 3242  bp: 3242  BP: 3243  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3243): < 'echo 9.1' > is a NORMAL COMMAND
pp: 3242  pt: 3224  cp: 3242  ct: 3224  lbp: 3240  bp: 3247  BP: 3242  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3242): < 'echo 9' > is a SIMPLE FORK *
pp: 3224  pt: 3224  cp: 3245  ct: 3224  lbp: 3235  bp: 3244  BP: 3245  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3245 > is a BACKGROUND FORK
pp: 3224  pt: 3224  cp: 3246  ct: 3224  lbp: 3235  bp: 3245  BP: 3246  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3246 > is a BACKGROUND FORK
9.1b
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3235  bp: 3249  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'echo 4' > is a SIMPLE FORK
pp: 3244  pt: 3224  cp: 3244  ct: 3224  lbp: 3243  bp: 3250  BP: 3244  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3244): < 'echo 9.1a' > is a SIMPLE FORK *
11
9.2a
9
pp: 3243  pt: 3224  cp: 3243  ct: 3224  lbp: 3242  bp: 3251  BP: 3243  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3243): < 'echo 9.2' > is a SIMPLE FORK
pp: 3245  pt: 3224  cp: 3245  ct: 3224  lbp: 3244  bp: 3244  BP: 3245  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3245): < 'echo 9.1b' > is a NORMAL COMMAND
pp: 3244  pt: 3224  cp: 3244  ct: 3224  lbp: 3250  bp: 3250  BP: 3244  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3244): < 'echo 9.2a' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3249  bp: 3249  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'echo 11' > is a NORMAL COMMAND
9.1c
pp: 3246  pt: 3224  cp: 3246  ct: 3224  lbp: 3245  bp: 3252  BP: 3246  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3246): < 'echo 9.1c' > is a SIMPLE FORK *
9.2c
pp: 3245  pt: 3224  cp: 3245  ct: 3224  lbp: 3244  bp: 3253  BP: 3245  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3245): < 'echo 9.2b' > is a SIMPLE FORK
pp: 3246  pt: 3224  cp: 3246  ct: 3224  lbp: 3252  bp: 3252  BP: 3246  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3246): < 'echo 9.2c' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3249  ct: 3256  lbp: 3235  bp: 3248  BP: 3249  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3249 > is a BACKGROUND FORK
pp: 3224  pt: 3224  cp: 3248  ct: 3256  lbp: 3235  bp: 3246  BP: 3248  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3248 > is a BACKGROUND FORK
9.999
9.2b
pp: 3224  pt: 3224  cp: 3256  ct: 3256  lbp: 3249  bp: 3255  BP: 3256  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3256 > is a SUBSHELL
14
pp: 3224  pt: 3224  cp: 3255  ct: 3256  lbp: 3249  bp: 3254  BP: 3255  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3255 > is a BACKGROUND FORK
9.1a
13
pp: 3249  pt: 3256  cp: 3249  ct: 3256  lbp: 3248  bp: 3257  BP: 3249  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3249): < 'echo 10' > is a SIMPLE FORK
12
pp: 3256  pt: 3256  cp: 3256  ct: 3256  lbp: 3255  bp: 3255  BP: 3256  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3256): < 'echo 14' > is a NORMAL COMMAND
9.2
pp: 3255  pt: 3256  cp: 3255  ct: 3256  lbp: 3254  bp: 3254  BP: 3255  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3255): < 'echo 13' > is a NORMAL COMMAND
10
pp: 3248  pt: 3256  cp: 3248  ct: 3256  lbp: 3246  bp: 3246  BP: 3258  BS: 3  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3248): < pid: 3258 > is a SUBSHELL
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3249  bp: 3255  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'echo 12' > is a SIMPLE FORK
9.3
pp: 3248  pt: 3256  cp: 3248  ct: 3256  lbp: 3246  bp: 3259  BP: 3258  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3258): < 'echo 9.3' > is a SIMPLE FORK
9.4
pp: 3248  pt: 3256  cp: 3248  ct: 3256  lbp: 3259  bp: 3259  BP: 3258  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3258): < 'echo 9.4' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3255  bp: 3255  BP: 3228  BS: 1  lBS: 1  F: 2  lF: 2 (ff)  PP: 3223  np: 1  (3228): < 'ff 15' > is a FUNCTION (C)
15
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3255  bp: 3255  BP: 3228  BS: 1  lBS: 1  F: 2  lF: 2 (ff)  PP: 3223  np: 1  (3228): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 3248  pt: 3256  cp: 3248  ct: 3256  lbp: 3246  bp: 3246  BP: 3248  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3248): < 'echo 9.999' > is a NORMAL COMMAND
9.5
pp: 3248  pt: 3256  cp: 3248  ct: 3256  lbp: 3246  bp: 3246  BP: 3248  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3248): < 'echo 9.5' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3255  bp: 3255  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'ff 15' > is a FUNCTION (P)
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3255  bp: 3255  BP: 3228  BS: 1  lBS: 1  F: 2  lF: 2 (gg)  PP: 3223  np: 1  (3228): < 'gg 16' > is a FUNCTION (C)
16
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3255  bp: 3255  BP: 3228  BS: 1  lBS: 1  F: 2  lF: 2 (gg)  PP: 3223  np: 1  (3228): < 'echo "$*"' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3255  bp: 3255  BP: 3228  BS: 1  lBS: 1  F: 3  lF: 3 (ff)  PP: 3223  np: 1  (3228): < 'ff "$@"' > is a FUNCTION (C)
16
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3255  bp: 3255  BP: 3228  BS: 1  lBS: 1  F: 3  lF: 3 (ff)  PP: 3223  np: 1  (3228): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3255  bp: 3255  BP: 3228  BS: 1  lBS: 1  F: 2  lF: 2 (gg)  PP: 3223  np: 1  (3228): < 'ff "$@"' > is a FUNCTION (P)
pp: 3224  pt: 3224  cp: 3260  ct: 3262  lbp: 3255  bp: 3255  BP: 3260  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3260 > is a BACKGROUND FORK
pp: 3224  pt: 3224  cp: 3261  ct: 3262  lbp: 3255  bp: 3260  BP: 3263  BS: 3  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3263 > is a BACKGROUND FORK
a
b
pp: 3260  pt: 3262  cp: 3260  ct: 3262  lbp: 3255  bp: 3265  BP: 3260  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3260): < 'echo a' > is a SIMPLE FORK
pp: 3224  pt: 3224  cp: 3262  ct: 3262  lbp: 3255  bp: 3264  BP: 3262  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3262 > is a SUBSHELL
pp: 3261  pt: 3262  cp: 3261  ct: 3262  lbp: 3260  bp: 3260  BP: 3263  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3263): < 'echo b' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3262  ct: 3262  lbp: 3255  bp: 3261  BP: 3266  BS: 4  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3266 > is a SUBSHELL
A2
A5
pp: 3262  pt: 3262  cp: 3262  ct: 3262  lbp: 3264  bp: 3267  BP: 3262  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3262): < 'echo A2' > is a SIMPLE FORK
A1
pp: 3262  pt: 3262  cp: 3262  ct: 3262  lbp: 3261  bp: 3268  BP: 3266  BS: 4  lBS: 4  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3266): < 'echo A5' > is a SIMPLE FORK
pp: 3262  pt: 3262  cp: 3262  ct: 3262  lbp: 3267  bp: 3267  BP: 3262  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3262): < 'echo A1' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3262  ct: 3224  lbp: 3255  bp: 3269  BP: 3264  BS: 3  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3264 > is a BACKGROUND FORK
A3
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3255  bp: 3261  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < ' (F) gg 16' > is a SIMPLE FORK
pp: 3224  pt: 3224  cp: 3262  ct: 3224  lbp: 3255  bp: 3261  BP: 3269  BS: 4  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3269 > is a BACKGROUND FORK
pp: 3262  pt: 3224  cp: 3262  ct: 3224  lbp: 3269  bp: 3269  BP: 3264  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3264): < 'echo A3' > is a NORMAL COMMAND
A4
pp: 3262  pt: 3224  cp: 3262  ct: 3224  lbp: 3261  bp: 3261  BP: 3269  BS: 4  lBS: 4  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3269): < 'echo A4' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < $'cat <<EOF\nfoo\nbar\nbaz\nEOF\n' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'grep foo' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'sed '\''s/o/O/g'\''' > is a NORMAL COMMAND
1
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 4  (3228): < 'wc -l' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3274  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 4  (3228): < pid: 3274 > is a SUBSHELL
today is 2025-06-16
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'echo "today is $(date +%Y-%m-%d)"' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3275  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3275 > is a SUBSHELL
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3276  BS: 3  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3276 > is a SUBSHELL
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3276  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3276): < 'echo nested' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3276  BS: 3  lBS: 3  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3276): < 'echo subshell' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3275  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 2  (3275): < 'grep sub' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'x=$( ( echo nested; echo subshell ) | grep sub)' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3261  BP: 3278  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3278 > is a SUBSHELL
pp: 3224  pt: 3224  cp: 3224  ct: 3280  lbp: 3261  bp: 3278  BP: 3279  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3279 > is a SUBSHELL
1,22c1,5
< bin
< boot
< dev
< etc
< home
< lib
< lib32
< lib64
< lib.usr-is-merged
< media
< mnt
< opt
< proc
< root
< run
< sbin
< script
< srv
< sys
< tmp
< usr
< var
---
> 3LAOQYG6P8PN3
> hsperfdata_root
> hsperfdata_runner84
> modules.timestamp
> TemporaryDirectory.QSoOif
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3261  bp: 3279  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'diff <(ls /) <(ls /tmp)' > is a SIMPLE FORK
pp: 3224  pt: 3224  cp: 3224  ct: 3282  lbp: 3279  bp: 3279  BP: 3281  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3281 > is a SUBSHELL
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3279  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'grep pattern <(sed '\''s/^/>>/'\'' > /dev/null)' > is a SIMPLE FORK
pp: 3224  pt: 3224  cp: 3283  ct: 3224  lbp: 3279  bp: 3281  BP: 3283  BS: 2  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < pid: 3283 > is a BACKGROUND FORK
pp: 3283  pt: 3224  cp: 3283  ct: 3224  lbp: 3281  bp: 3281  BP: 3283  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3283): < 'for i in {1..3}' > is a NORMAL COMMAND
pp: 3283  pt: 3224  cp: 3283  ct: 3224  lbp: 3281  bp: 3281  BP: 3283  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3283): < 'echo "$i"' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 1
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
pp: 3283  pt: 3224  cp: 3283  ct: 3224  lbp: 3281  bp: 3281  BP: 3283  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3283): < 'sleep .01' > is a NORMAL COMMAND
pp: 3283  pt: 3224  cp: 3283  ct: 3224  lbp: 3281  bp: 3281  BP: 3283  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3283): < 'for i in {1..3}' > is a NORMAL COMMAND
pp: 3283  pt: 3224  cp: 3283  ct: 3224  lbp: 3281  bp: 3281  BP: 3283  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3283): < 'echo "$i"' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 2
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
pp: 3283  pt: 3224  cp: 3283  ct: 3224  lbp: 3281  bp: 3281  BP: 3283  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3283): < 'sleep .01' > is a NORMAL COMMAND
pp: 3283  pt: 3224  cp: 3283  ct: 3224  lbp: 3281  bp: 3281  BP: 3283  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3283): < 'for i in {1..3}' > is a NORMAL COMMAND
pp: 3283  pt: 3224  cp: 3283  ct: 3224  lbp: 3281  bp: 3281  BP: 3283  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3283): < 'echo "$i"' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got 3
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
pp: 3283  pt: 3224  cp: 3283  ct: 3224  lbp: 3281  bp: 3281  BP: 3283  BS: 2  lBS: 2  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3283): < 'sleep .01' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'let "x = 5 + 6"' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'arr=(one two three)' > is a NORMAL COMMAND
one two three
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'echo ${arr[@]}' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < '((i=0))' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < '((i<3))' > is a NORMAL COMMAND
0
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'echo "$i"' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < '((i++))' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < '((i<3))' > is a NORMAL COMMAND
1
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'echo "$i"' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < '((i++))' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < '((i<3))' > is a NORMAL COMMAND
2
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'echo "$i"' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < '((i++))' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < '((i<3))' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'cmd="echo inside-eval"' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'eval "$cmd"' > is a NORMAL COMMAND
inside-eval
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'echo inside-eval' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'eval "eval \"$cmd\""' > is a NORMAL COMMAND
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'eval "echo inside-eval"' > is a NORMAL COMMAND
inside-eval
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 2  lF: 2 (trap)  PP: 3223  np: 1  (3228): < 'skip_debug=true' > is a FUNCTION (C)
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'skip_debug=true' > is a FUNCTION (P)
pp: 3224  pt: 3224  cp: 3224  ct: 3224  lbp: 3283  bp: 3283  BP: 3228  BS: 1  lBS: 1  F: 0  lF: 0 (main)  PP: 3223  np: 1  (3228): < 'kill -USR1 $$' > is a NORMAL COMMAND


EOF











#####################################################################################################################
(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=()
last_funcdepth=${#FUNCNAME[@]}
last_command[$last_funcdepth]=''
subshell_pid=''
next_is_simple_fork_flag=false
this_is_simple_fork_flag=false

trap() {
    skip_debug=true
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap ':' EXIT ;;
            RETURN)  builtin trap ':' RETURN ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
        skip_debug=false
}

export -f trap


skip_debug=false

builtin trap 'wait -f' EXIT RETURN

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

builtin trap 'npipe0=${#PIPESTATUS[@]}
${skip_debug} || [[ "${BASH_COMMAND}" == trap* ]] || {
npipe=$npipe0
is_bg=false
is_subshell=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  (( last_bg_pid == $! )) || is_bg=true
else
  is_subshell=true
  subshell_pid=$BASHPID 
  builtin trap '"'"'wait -f'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == parent_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
  cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
elif (( ${#FUNCNAME[@]} > last_funcdepth )); then
  cmd_type="FUNCTION"
  last_funcdepth=${#FUNCNAME[@]}
else
  last_funcdepth=${#FUNCNAME[@]}
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   fd: %s    lfd: %s    PP: %s    np: %s    (%s): < pid: %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" ${#FUNCNAME[@]} $last_funcdepth "${PPID:-\?}" $npipe "$last_pid" "$BASHPID" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ $last_command ]]; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   fd: %s    lfd: %s    PP: %s    np: %s    (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" ${#FUNCNAME[@]} $last_funcdepth "${PPID:-\?}" $npipe "$BASHPID" "${last_command@Q}" "$cmd_type"
fi >&$fd
last_command="$BASH_COMMAND"
last_bg_pid=$!
last_pid=$BASHPID
}' DEBUG

:

{ echo ; } &
{ ( echo A & ); echo B; } &

:
    
trap - DEBUG EXIT RETURN

) {fd}>&2


(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=()
last_funcdepth=${#FUNCNAME[@]}
last_command[$last_funcdepth]=''
subshell_pid=''
next_is_simple_fork_flag=false
this_is_simple_fork_flag=false

trap() {
    skip_debug=true
    local trapStr trapType

    if [[ "${1}" == -[lp] ]]; then
        builtin trap "${@}"
        return
    else
        [[ "${1}" == '--' ]] && shift 1
        trapStr="${1%\;}"$'\n'
        shift 1
        if [[ "${trapStr}" == '-'$'\n' ]] || [[ "$trapStr" == $'\n' ]]; then
            trapStr=''
        fi
    fi

    for trapType in "${@}"; do
        case "${trapType}" in
            EXIT)    builtin trap ':' EXIT ;;
            RETURN)  builtin trap ':' RETURN ;;
            *)       eval "builtin trap ${trapStr@Q} ${trapType}" ;;
        esac
    done
        skip_debug=false
}

export -f trap


skip_debug=false

builtin trap 'wait -f' EXIT RETURN

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

builtin trap 'npipe0=${#PIPESTATUS[@]}
${skip_debug} || [[ "${BASH_COMMAND}" == trap* ]] || {
npipe=$npipe0
is_bg=false
is_subshell=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  (( last_bg_pid == $! )) || is_bg=true
else
  is_subshell=true
  subshell_pid=$BASHPID 
  builtin trap '"'"'wait -f'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == parent_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
  cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
elif ${is_func}; then
  cmd_type="FUNCTION"
  is_func=false
else
  cmd_type="NORMAL COMMAND"
fi
${is_subshell} || ${is_bg} || (( ${#FUNCNAME[@]} <= last_funcdepth )) || is_func=true
if ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   fd: %s    lfd: %s    PP: %s    np: %s    (%s): < pid: %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" ${#FUNCNAME[@]} $last_funcdepth "${PPID:-\?}" $npipe "$last_pid" "$BASHPID" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ $last_command ]] && (( ${#FUNCNAME[@]} == last_funcdepth )) then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   fd: %s    lfd: %s    PP: %s    np: %s    (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" ${#FUNCNAME[@]} $last_funcdepth "${PPID:-\?}" $npipe "$BASHPID" "${last_command@Q}" "$cmd_type"
fi >&$fd
last_command="$BASH_COMMAND"
last_bg_pid=$!
last_pid=$BASHPID
last_funcdepth=${#FUNCNAME[@]}
}' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &


( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


cat <<EOF | grep foo | sed 's/o/O/g' | wc -l
foo
bar
baz
EOF

echo "today is $(date +%Y-%m-%d)"
x=$( (echo nested; echo subshell) | grep sub )

diff <(ls /) <(ls /tmp)
grep pattern <(sed 's/^/>>/' > /dev/null)

coproc CO { for i in {1..3}; do echo "$i"; sleep .01; done; }
while read -r n <&${CO[0]}; do printf "got %s\n" "$n"; done

let "x = 5 + 6"
arr=( one two three ); echo ${arr[@]}
for ((i=0;i<3;i++)); do echo "$i"; done

hh() {
  trap 'echo in-ff-EXIT' EXIT
  echo before
  (
    trap 'echo in-sub-EXIT' EXIT
    echo in subshell
  )
  echo after
}


cmd="echo inside-eval"
eval "$cmd"
eval "eval \"$cmd\""

trap 'echo got USR1; sleep .01' USR1
kill -USR1 $$
echo after-signal

for i in {1..3}; do
  while read x; do
    if (( x % 2 == 0 )); then
      echo even "$x"
    else
      ( echo odd "$x" )
    fi
  done < <(seq 1 5)
done

hh
trap - DEBUG

) {fd}>&2


:<<'EOF'

0
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 748  bp: 748   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'echo 0' > is a NORMAL COMMAND
1
pp: 743   pt: 743   cp: 749   ct: 749   lbp: 748  bp: 748   BP: 749  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 749 > is a SUBSHELL
2
pp: 749   pt: 749   cp: 749   ct: 749   lbp: 748  bp: 748   BP: 749  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (749): < 'echo 2' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 748  bp: 748   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'echo 1' > is a NORMAL COMMAND
3
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 748  bp: 750   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'echo 3' > is a SIMPLE FORK
4
pp: 743   pt: 743   cp: 752   ct: 753   lbp: 750  bp: 751   BP: 752  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 752 > is a BACKGROUND FORK
5
pp: 743   pt: 743   cp: 753   ct: 753   lbp: 750  bp: 752   BP: 753  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 753 > is a SUBSHELL
pp: 752   pt: 753   cp: 752   ct: 753   lbp: 751  bp: 751   BP: 752  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (752): < 'echo 5' > is a NORMAL COMMAND
6
pp: 753   pt: 753   cp: 753   ct: 753   lbp: 752  bp: 754   BP: 753  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (753): < 'echo 6' > is a SIMPLE FORK
pp: 743   pt: 743   cp: 755   ct: 756   lbp: 750  bp: 752   BP: 755  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 755 > is a BACKGROUND FORK
7
pp: 743   pt: 743   cp: 756   ct: 756   lbp: 750  bp: 755   BP: 756  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 756 > is a SUBSHELL
8
pp: 755   pt: 756   cp: 755   ct: 756   lbp: 752  bp: 752   BP: 755  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (755): < 'echo 7' > is a NORMAL COMMAND
pp: 756   pt: 756   cp: 756   ct: 756   lbp: 755  bp: 755   BP: 756  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (756): < 'echo 8' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 757   ct: 743   lbp: 750  bp: 755   BP: 757  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 757 > is a BACKGROUND FORK
pp: 743   pt: 743   cp: 761   ct: 743   lbp: 750  bp: 760   BP: 761  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 761 > is a BACKGROUND FORK
pp: 743   pt: 743   cp: 762   ct: 743   lbp: 750  bp: 761   BP: 762  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 762 > is a BACKGROUND FORK
pp: 743   pt: 743   cp: 758   ct: 743   lbp: 750  bp: 757   BP: 758  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 758 > is a BACKGROUND FORK
pp: 743   pt: 743   cp: 763   ct: 743   lbp: 750  bp: 762   BP: 763  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 763 > is a BACKGROUND FORK
pp: 743   pt: 743   cp: 759   ct: 743   lbp: 750  bp: 758   BP: 759  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 759 > is a BACKGROUND FORK
9.999
pp: 743   pt: 743   cp: 760   ct: 743   lbp: 750  bp: 759   BP: 760  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 760 > is a BACKGROUND FORK
9.1b
pp: 757   pt: 743   cp: 757   ct: 743   lbp: 755  bp: 764   BP: 757  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (757): < 'echo 9' > is a SIMPLE FORK *
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 750  bp: 763   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'echo 4' > is a SIMPLE FORK
9.1
11
pp: 761   pt: 743   cp: 761   ct: 743   lbp: 760  bp: 765   BP: 761  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (761): < 'echo 9.1c' > is a SIMPLE FORK *
9.2c
pp: 760   pt: 743   cp: 760   ct: 743   lbp: 759  bp: 759   BP: 760  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (760): < 'echo 9.1b' > is a NORMAL COMMAND
pp: 758   pt: 743   cp: 758   ct: 743   lbp: 757  bp: 757   BP: 758  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (758): < 'echo 9.1' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 763  bp: 763   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'echo 11' > is a NORMAL COMMAND
pp: 761   pt: 743   cp: 761   ct: 743   lbp: 765  bp: 765   BP: 761  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (761): < 'echo 9.2c' > is a NORMAL COMMAND
9
pp: 760   pt: 743   cp: 760   ct: 743   lbp: 759  bp: 769   BP: 760  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (760): < 'echo 9.2b' > is a SIMPLE FORK
9.1c
9.1a
pp: 762   pt: 743   cp: 762   ct: 773   lbp: 761  bp: 761   BP: 766  BS: 3   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (762): < pid: 766 > is a BACKGROUND FORK
pp: 759   pt: 743   cp: 759   ct: 743   lbp: 758  bp: 767   BP: 759  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (759): < 'echo 9.1a' > is a SIMPLE FORK *
9.2a
pp: 758   pt: 743   cp: 758   ct: 743   lbp: 757  bp: 770   BP: 758  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (758): < 'echo 9.2' > is a SIMPLE FORK
pp: 763   pt: 743   cp: 763   ct: 743   lbp: 762  bp: 768   BP: 763  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (763): < 'echo 10' > is a SIMPLE FORK *
pp: 762   pt: 773   cp: 762   ct: 773   lbp: 761  bp: 774   BP: 766  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 742    np: 1    (766): < 'echo 9.3' > is a SIMPLE FORK
12
10
pp: 743   pt: 743   cp: 773   ct: 762   lbp: 763  bp: 772   BP: 773  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 773 > is a BACKGROUND FORK
9.4
9.2b
14
pp: 759   pt: 743   cp: 759   ct: 743   lbp: 767  bp: 767   BP: 759  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (759): < 'echo 9.2a' > is a NORMAL COMMAND
pp: 762   pt: 773   cp: 762   ct: 773   lbp: 774  bp: 774   BP: 766  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 742    np: 1    (766): < 'echo 9.4' > is a NORMAL COMMAND
pp: 773   pt: 762   cp: 773   ct: 762   lbp: 772  bp: 772   BP: 773  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (773): < 'echo 14' > is a NORMAL COMMAND
9.2
9.3
pp: 762   pt: 743   cp: 762   ct: 743   lbp: 761  bp: 761   BP: 762  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (762): < 'echo 9.999' > is a NORMAL COMMAND
9.5
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 763  bp: 772   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'echo 12' > is a SIMPLE FORK
pp: 762   pt: 743   cp: 762   ct: 743   lbp: 761  bp: 761   BP: 762  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (762): < 'echo 9.5' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 772   ct: 743   lbp: 763  bp: 771   BP: 772  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 772 > is a BACKGROUND FORK
13
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 772  bp: 772   BP: 747  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 742    np: 1    (747): < 'ff 15' > is a FUNCTION
15
pp: 772   pt: 743   cp: 772   ct: 743   lbp: 771  bp: 771   BP: 772  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (772): < 'echo 13' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 772  bp: 772   BP: 747  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 742    np: 1    (747): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 772  bp: 772   BP: 747  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 742    np: 1    (747): < 'gg 16' > is a FUNCTION
16
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 772  bp: 772   BP: 747  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 742    np: 1    (747): < 'echo "$*"' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 772  bp: 772   BP: 747  BS: 1   lBS: 1   fd: 3    lfd: 3    PP: 742    np: 1    (747): < 'ff "$@"' > is a FUNCTION
16
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 772  bp: 772   BP: 747  BS: 1   lBS: 1   fd: 3    lfd: 3    PP: 742    np: 1    (747): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 775   ct: 777   lbp: 772  bp: 772   BP: 775  BS: 2   lBS: 1   fd: 0    lfd: 2    PP: 742    np: 1    (747): < pid: 775 > is a BACKGROUND FORK
a
pp: 743   pt: 743   cp: 776   ct: 777   lbp: 772  bp: 775   BP: 778  BS: 3   lBS: 1   fd: 0    lfd: 2    PP: 742    np: 1    (747): < pid: 778 > is a BACKGROUND FORK
b
pp: 775   pt: 777   cp: 775   ct: 777   lbp: 772  bp: 780   BP: 775  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (775): < 'echo a' > is a SIMPLE FORK
pp: 743   pt: 743   cp: 777   ct: 777   lbp: 772  bp: 779   BP: 777  BS: 2   lBS: 1   fd: 0    lfd: 2    PP: 742    np: 1    (747): < pid: 777 > is a SUBSHELL
pp: 776   pt: 777   cp: 776   ct: 777   lbp: 775  bp: 775   BP: 778  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 742    np: 1    (778): < 'echo b' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 777   ct: 777   lbp: 772  bp: 776   BP: 781  BS: 4   lBS: 1   fd: 0    lfd: 2    PP: 742    np: 1    (747): < pid: 781 > is a SUBSHELL
pp: 777   pt: 777   cp: 777   ct: 777   lbp: 779  bp: 782   BP: 777  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (777): < 'echo A2' > is a SIMPLE FORK
A1
A5
pp: 777   pt: 777   cp: 777   ct: 777   lbp: 782  bp: 782   BP: 777  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (777): < 'echo A1' > is a NORMAL COMMAND
pp: 777   pt: 777   cp: 777   ct: 777   lbp: 776  bp: 783   BP: 781  BS: 4   lBS: 4   fd: 0    lfd: 0    PP: 742    np: 1    (781): < 'echo A5' > is a SIMPLE FORK
A2
pp: 743   pt: 743   cp: 777   ct: 743   lbp: 772  bp: 784   BP: 779  BS: 3   lBS: 1   fd: 0    lfd: 2    PP: 742    np: 1    (747): < pid: 779 > is a BACKGROUND FORK
A3
pp: 743   pt: 743   cp: 777   ct: 743   lbp: 772  bp: 776   BP: 784  BS: 4   lBS: 1   fd: 0    lfd: 2    PP: 742    np: 1    (747): < pid: 784 > is a BACKGROUND FORK
A4
pp: 777   pt: 743   cp: 777   ct: 743   lbp: 784  bp: 784   BP: 779  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 742    np: 1    (779): < 'echo A3' > is a NORMAL COMMAND
pp: 777   pt: 743   cp: 777   ct: 743   lbp: 776  bp: 776   BP: 784  BS: 4   lBS: 4   fd: 0    lfd: 0    PP: 742    np: 1    (784): < 'echo A4' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < $'cat <<EOF\nfoo\nbar\nbaz\nEOF\n' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'grep foo' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'sed '\''s/o/O/g'\''' > is a NORMAL COMMAND
1
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 4    (747): < 'wc -l' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 789  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 4    (747): < pid: 789 > is a SUBSHELL
today is 2025-06-14
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'echo "today is $(date +%Y-%m-%d)"' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 790  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 790 > is a SUBSHELL
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 791  BS: 3   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 791 > is a SUBSHELL
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 791  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 742    np: 1    (791): < 'echo nested' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 791  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 742    np: 1    (791): < 'echo subshell' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 790  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 2    (790): < 'grep sub' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'x=$( ( echo nested; echo subshell ) | grep sub)' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 776   BP: 793  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 793 > is a SUBSHELL
pp: 743   pt: 743   cp: 743   ct: 795   lbp: 776  bp: 793   BP: 794  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 794 > is a SUBSHELL
1,22d0
< bin
< boot
< dev
< etc
< home
< lib
< lib32
< lib64
< lib.usr-is-merged
< media
< mnt
< opt
< proc
< root
< run
< sbin
< script
< srv
< sys
< tmp
< usr
< var
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 776  bp: 794   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'diff <(ls /) <(ls /tmp)' > is a SIMPLE FORK
pp: 743   pt: 743   cp: 743   ct: 797   lbp: 794  bp: 794   BP: 796  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 796 > is a SUBSHELL
sed: read error on stdin: Input/output error
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 794  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'grep pattern <(sed '\''s/^/>>/'\'' > /dev/null)' > is a SIMPLE FORK
pp: 743   pt: 743   cp: 798   ct: 743   lbp: 794  bp: 796   BP: 798  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < pid: 798 > is a BACKGROUND FORK
pp: 798   pt: 743   cp: 798   ct: 743   lbp: 796  bp: 796   BP: 798  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (798): < 'for i in {1..3}' > is a NORMAL COMMAND
pp: 798   pt: 743   cp: 798   ct: 743   lbp: 796  bp: 796   BP: 798  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (798): < 'echo "$i"' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got "1"
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
pp: 798   pt: 743   cp: 798   ct: 743   lbp: 796  bp: 796   BP: 798  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (798): < 'sleep .01' > is a NORMAL COMMAND
pp: 798   pt: 743   cp: 798   ct: 743   lbp: 796  bp: 796   BP: 798  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (798): < 'for i in {1..3}' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
pp: 798   pt: 743   cp: 798   ct: 743   lbp: 796  bp: 796   BP: 798  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (798): < 'echo "$i"' > is a NORMAL COMMAND
got "2"
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
pp: 798   pt: 743   cp: 798   ct: 743   lbp: 796  bp: 796   BP: 798  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (798): < 'sleep .01' > is a NORMAL COMMAND
pp: 798   pt: 743   cp: 798   ct: 743   lbp: 796  bp: 796   BP: 798  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (798): < 'for i in {1..3}' > is a NORMAL COMMAND
pp: 798   pt: 743   cp: 798   ct: 743   lbp: 796  bp: 796   BP: 798  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (798): < 'echo "$i"' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
got "3"
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'printf "got %s\n" "$n"' > is a NORMAL COMMAND
pp: 798   pt: 743   cp: 798   ct: 743   lbp: 796  bp: 796   BP: 798  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 742    np: 1    (798): < 'sleep .01' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'read -r n <&${CO[0]}' > is a NORMAL COMMAND
main.bash: line 155: let: "x: syntax error: operand expected (error token is ""x")
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'let "x = 5 + 6"' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'arr=(one two three)' > is a NORMAL COMMAND
one two three
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'echo ${arr[@]}' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < '((i=0))' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < '((i<3))' > is a NORMAL COMMAND
"0"
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'echo "$i"' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < '((i++))' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < '((i<3))' > is a NORMAL COMMAND
"1"
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'echo "$i"' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < '((i++))' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < '((i<3))' > is a NORMAL COMMAND
"2"
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'echo "$i"' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < '((i++))' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < '((i<3))' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'cmd="echo inside-eval"' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'eval "$cmd"' > is a NORMAL COMMAND
inside-eval
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'echo inside-eval' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'eval "eval \"$cmd\""' > is a NORMAL COMMAND
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 742    np: 1    (747): < 'eval "echo inside-eval"' > is a NORMAL COMMAND
inside-eval
pp: 743   pt: 743   cp: 743   ct: 743   lbp: 798  bp: 798   BP: 747  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 742    np: 1    (747): < 'skip_debug=true' > is a FUNCTION

EOF


#################################################################################

(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=()
last_funcdepth=${#FUNCNAME[@]}
last_command[$last_funcdepth]=''
subshell_pid=''
next_is_simple_fork_flag=false
this_is_simple_fork_flag=false

trap 'wait -f' EXIT RETURN

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

trap 'is_bg=false
is_subshell=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  (( last_bg_pid == $! )) || is_bg=true
else
  is_subshell=true
  subshell_pid=$BASHPID 
  trap '"'"'wait -f'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == parent_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
  cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
elif ${is_func}; then
  cmd_type="FUNCTION"
  is_func=false
else
  cmd_type="NORMAL COMMAND"
fi
${is_subshell} || ${is_bg} || (( ${#FUNCNAME[@]} <= last_funcdepth )) || is_func=true
if ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   fd: %s    lfd: %s    PP: %s    (%s): < pid: %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" ${#FUNCNAME[@]} $last_funcdepth "${PPID:-\?}" "$last_pid" "$BASHPID" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ $last_command ]] && (( ${#FUNCNAME[@]} == last_funcdepth )) then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   fd: %s    lfd: %s    PP: %s    (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" ${#FUNCNAME[@]} $last_funcdepth "${PPID:-\?}" "$BASHPID" "${last_command@Q}" "$cmd_type"
fi >&$fd
last_command="$BASH_COMMAND"
last_bg_pid=$!
last_pid=$BASHPID
last_funcdepth=${#FUNCNAME[@]}
' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &


( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


trap - DEBUG

) {fd}>&2

:<<'EOF
pp: 13031   pt: 13031   cp: 13031   ct: 13031   lbp: 13036  bp: 13036   BP: 13035  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < 'echo 0' > is a NORMAL COMMAND
1
pp: 13031   pt: 13031   cp: 13037   ct: 13037   lbp: 13036  bp: 13036   BP: 13037  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13037 > is a SUBSHELL
2
pp: 13037   pt: 13037   cp: 13037   ct: 13037   lbp: 13036  bp: 13036   BP: 13037  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13037): < 'echo 2' > is a NORMAL COMMAND
pp: 13031   pt: 13031   cp: 13031   ct: 13031   lbp: 13036  bp: 13036   BP: 13035  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < 'echo 1' > is a NORMAL COMMAND
3
pp: 13031   pt: 13031   cp: 13031   ct: 13031   lbp: 13036  bp: 13038   BP: 13035  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < 'echo 3' > is a SIMPLE FORK
4
pp: 13031   pt: 13031   cp: 13040   ct: 13041   lbp: 13038  bp: 13039   BP: 13040  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13040 > is a BACKGROUND FORK
5
pp: 13031   pt: 13031   cp: 13041   ct: 13041   lbp: 13038  bp: 13040   BP: 13041  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13041 > is a SUBSHELL
pp: 13040   pt: 13041   cp: 13040   ct: 13041   lbp: 13039  bp: 13039   BP: 13040  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13040): < 'echo 5' > is a NORMAL COMMAND
6
pp: 13041   pt: 13041   cp: 13041   ct: 13041   lbp: 13040  bp: 13042   BP: 13041  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13041): < 'echo 6' > is a SIMPLE FORK
pp: 13031   pt: 13031   cp: 13043   ct: 13044   lbp: 13038  bp: 13040   BP: 13043  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13043 > is a BACKGROUND FORK
7
pp: 13043   pt: 13044   cp: 13043   ct: 13044   lbp: 13040  bp: 13040   BP: 13043  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13043): < 'echo 7' > is a NORMAL COMMAND
pp: 13031   pt: 13031   cp: 13044   ct: 13044   lbp: 13038  bp: 13043   BP: 13044  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13044 > is a SUBSHELL
8
pp: 13044   pt: 13044   cp: 13044   ct: 13044   lbp: 13043  bp: 13043   BP: 13044  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13044): < 'echo 8' > is a NORMAL COMMAND
pp: 13031   pt: 13031   cp: 13045   ct: 13031   lbp: 13038  bp: 13043   BP: 13045  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13045 > is a BACKGROUND FORK
pp: 13031   pt: 13031   cp: 13046   ct: 13031   lbp: 13038  bp: 13045   BP: 13046  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13046 > is a BACKGROUND FORK
9.1
9
pp: 13031   pt: 13031   cp: 13047   ct: 13031   lbp: 13038  bp: 13046   BP: 13047  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13047 > is a BACKGROUND FORK
pp: 13046   pt: 13031   cp: 13046   ct: 13031   lbp: 13045  bp: 13045   BP: 13046  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13046): < 'echo 9.1' > is a NORMAL COMMAND
pp: 13045   pt: 13031   cp: 13045   ct: 13031   lbp: 13043  bp: 13050   BP: 13045  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13045): < 'echo 9' > is a SIMPLE FORK *
pp: 13031   pt: 13031   cp: 13048   ct: 13031   lbp: 13038  bp: 13047   BP: 13048  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13048 > is a BACKGROUND FORK
9.1b
pp: 13031   pt: 13031   cp: 13031   ct: 13031   lbp: 13038  bp: 13052   BP: 13035  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < 'echo 4' > is a SIMPLE FORK
pp: 13048   pt: 13031   cp: 13048   ct: 13031   lbp: 13047  bp: 13047   BP: 13048  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13048): < 'echo 9.1b' > is a NORMAL COMMAND
pp: 13047   pt: 13031   cp: 13047   ct: 13031   lbp: 13046  bp: 13053   BP: 13047  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13047): < 'echo 9.1a' > is a SIMPLE FORK *
11
9.2a
pp: 13046   pt: 13031   cp: 13046   ct: 13031   lbp: 13045  bp: 13054   BP: 13046  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13046): < 'echo 9.2' > is a SIMPLE FORK
pp: 13031   pt: 13031   cp: 13049   ct: 13031   lbp: 13038  bp: 13048   BP: 13049  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13049 > is a BACKGROUND FORK
pp: 13031   pt: 13031   cp: 13031   ct: 13031   lbp: 13052  bp: 13052   BP: 13035  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < 'echo 11' > is a NORMAL COMMAND
pp: 13047   pt: 13031   cp: 13047   ct: 13031   lbp: 13053  bp: 13053   BP: 13047  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13047): < 'echo 9.2a' > is a NORMAL COMMAND
9.2
pp: 13048   pt: 13031   cp: 13048   ct: 13031   lbp: 13047  bp: 13055   BP: 13048  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13048): < 'echo 9.2b' > is a SIMPLE FORK
pp: 13031   pt: 13031   cp: 13051   ct: 13031   lbp: 13038  bp: 13049   BP: 13051  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13051 > is a BACKGROUND FORK
9.1c
9.999
9.1a
pp: 13049   pt: 13031   cp: 13049   ct: 13031   lbp: 13048  bp: 13056   BP: 13049  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13049): < 'echo 9.1c' > is a SIMPLE FORK *
9.2b
9.2c
pp: 13031   pt: 13031   cp: 13052   ct: 13060   lbp: 13038  bp: 13051   BP: 13052  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13052 > is a BACKGROUND FORK
12
pp: 13049   pt: 13031   cp: 13049   ct: 13031   lbp: 13056  bp: 13056   BP: 13049  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13049): < 'echo 9.2c' > is a NORMAL COMMAND
pp: 13051   pt: 13031   cp: 13051   ct: 13060   lbp: 13049  bp: 13049   BP: 13059  BS: 3   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13051): < pid: 13059 > is a BACKGROUND FORK
pp: 13031   pt: 13031   cp: 13060   ct: 13060   lbp: 13052  bp: 13058   BP: 13060  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13060 > is a SUBSHELL
14
pp: 13031   pt: 13031   cp: 13058   ct: 13060   lbp: 13052  bp: 13057   BP: 13058  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < pid: 13058 > is a BACKGROUND FORK
pp: 13052   pt: 13060   cp: 13052   ct: 13060   lbp: 13051  bp: 13061   BP: 13052  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13052): < 'echo 10' > is a SIMPLE FORK
13
pp: 13060   pt: 13060   cp: 13060   ct: 13060   lbp: 13058  bp: 13058   BP: 13060  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13060): < 'echo 14' > is a NORMAL COMMAND
9.3
10
pp: 13051   pt: 13060   cp: 13051   ct: 13060   lbp: 13049  bp: 13062   BP: 13059  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 13030    (13059): < 'echo 9.3' > is a SIMPLE FORK
9.4
pp: 13058   pt: 13060   cp: 13058   ct: 13060   lbp: 13057  bp: 13057   BP: 13058  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13058): < 'echo 13' > is a NORMAL COMMAND
pp: 13031   pt: 13031   cp: 13031   ct: 13031   lbp: 13052  bp: 13058   BP: 13035  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 13030    (13035): < 'echo 12' > is a SIMPLE FORK
pp: 13051   pt: 13060   cp: 13051   ct: 13060   lbp: 13062  bp: 13062   BP: 13059  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 13030    (13059): < 'echo 9.4' > is a NORMAL COMMAND
pp: 13031   pt: 13031   cp: 13031   ct: 13031   lbp: 13058  bp: 13058   BP: 13035  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 13030    (13035): < 'ff 15' > is a FUNCTION
pp: 13051   pt: 13031   cp: 13051   ct: 13031   lbp: 13049  bp: 13049   BP: 13051  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13051): < 'echo 9.999' > is a NORMAL COMMAND
15
9.5
pp: 13031   pt: 13031   cp: 13031   ct: 13031   lbp: 13058  bp: 13058   BP: 13035  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 13030    (13035): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 13051   pt: 13031   cp: 13051   ct: 13031   lbp: 13049  bp: 13049   BP: 13051  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13051): < 'echo 9.5' > is a NORMAL COMMAND
pp: 13031   pt: 13031   cp: 13031   ct: 13031   lbp: 13058  bp: 13058   BP: 13035  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 13030    (13035): < 'gg 16' > is a FUNCTION
16
pp: 13031   pt: 13031   cp: 13031   ct: 13031   lbp: 13058  bp: 13058   BP: 13035  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 13030    (13035): < 'echo "$*"' > is a NORMAL COMMAND
pp: 13031   pt: 13031   cp: 13031   ct: 13031   lbp: 13058  bp: 13058   BP: 13035  BS: 1   lBS: 1   fd: 3    lfd: 3    PP: 13030    (13035): < 'ff "$@"' > is a FUNCTION
16
pp: 13031   pt: 13031   cp: 13031   ct: 13031   lbp: 13058  bp: 13058   BP: 13035  BS: 1   lBS: 1   fd: 3    lfd: 3    PP: 13030    (13035): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 13031   pt: 13031   cp: 13063   ct: 13065   lbp: 13058  bp: 13058   BP: 13063  BS: 2   lBS: 1   fd: 0    lfd: 2    PP: 13030    (13035): < pid: 13063 > is a BACKGROUND FORK
pp: 13031   pt: 13031   cp: 13064   ct: 13065   lbp: 13058  bp: 13063   BP: 13066  BS: 3   lBS: 1   fd: 0    lfd: 2    PP: 13030    (13035): < pid: 13066 > is a BACKGROUND FORK
a
b
pp: 13031   pt: 13031   cp: 13065   ct: 13065   lbp: 13058  bp: 13067   BP: 13065  BS: 2   lBS: 1   fd: 0    lfd: 2    PP: 13030    (13035): < pid: 13065 > is a SUBSHELL
pp: 13063   pt: 13065   cp: 13063   ct: 13065   lbp: 13058  bp: 13068   BP: 13063  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13063): < 'echo a' > is a SIMPLE FORK
pp: 13064   pt: 13065   cp: 13064   ct: 13065   lbp: 13063  bp: 13063   BP: 13066  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 13030    (13066): < 'echo b' > is a NORMAL COMMAND
pp: 13031   pt: 13031   cp: 13065   ct: 13065   lbp: 13058  bp: 13064   BP: 13069  BS: 4   lBS: 1   fd: 0    lfd: 2    PP: 13030    (13035): < pid: 13069 > is a SUBSHELL
A2
pp: 13065   pt: 13065   cp: 13065   ct: 13065   lbp: 13067  bp: 13070   BP: 13065  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13065): < 'echo A2' > is a SIMPLE FORK
A1
A5
pp: 13065   pt: 13065   cp: 13065   ct: 13065   lbp: 13070  bp: 13070   BP: 13065  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 13030    (13065): < 'echo A1' > is a NORMAL COMMAND
pp: 13065   pt: 13065   cp: 13065   ct: 13065   lbp: 13064  bp: 13071   BP: 13069  BS: 4   lBS: 4   fd: 0    lfd: 0    PP: 13030    (13069): < 'echo A5' > is a SIMPLE FORK
pp: 13031   pt: 13031   cp: 13065   ct: 13031   lbp: 13058  bp: 13064   BP: 13072  BS: 4   lBS: 1   fd: 0    lfd: 2    PP: 13030    (13035): < pid: 13072 > is a BACKGROUND FORK
A4
pp: 13031   pt: 13031   cp: 13065   ct: 13031   lbp: 13058  bp: 13072   BP: 13067  BS: 3   lBS: 1   fd: 0    lfd: 2    PP: 13030    (13035): < pid: 13067 > is a BACKGROUND FORK
A3
pp: 13065   pt: 13031   cp: 13065   ct: 13031   lbp: 13064  bp: 13064   BP: 13072  BS: 4   lBS: 4   fd: 0    lfd: 0    PP: 13030    (13072): < 'echo A4' > is a NORMAL COMMAND
pp: 13065   pt: 13031   cp: 13065   ct: 13031   lbp: 13072  bp: 13072   BP: 13067  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 13030    (13067): < 'echo A3' > is a NORMAL COMMAND
EOF

#########################################################################
(

set -T
set -m
set -b

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=()
last_funcdepth=${#FUNCNAME[@]}
last_command[$last_funcdepth]=''
subshell_pid=''
next_is_simple_fork_flag=false
this_is_simple_fork_flag=false

trap 'wait -f' EXIT RETURN

ff() { echo "${*}"; }
gg() { echo "$*"; ff "$@"; }

trap 'is_bg=false
is_subshell=false
is_func_exit=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  (( last_bg_pid == $! )) || is_bg=true
else
  is_subshell=true
  subshell_pid=$BASHPID 
  trap '"'"'wait'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == parent_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
  cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
elif ${is_func}; then
  cmd_type="FUNCTION"
  is_func=false
else
  cmd_type="NORMAL COMMAND"
fi
${is_subshell} || ${is_bg} || {
  if (( ${#FUNCNAME[@]} > last_funcdepth )); then
    is_func=true
  elif (( ${#FUNCNAME[@]} < last_funcdepth )); then
    is_func_exit=true
  fi
}
if ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   fd: %s    lfd: %s    PP: %s    (%s): < pid: %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" ${#FUNCNAME[@]} $last_funcdepth "${PPID:-\?}" "$last_pid" "$BASHPID" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ $last_command ]] && ! ${is_func} && ! ${is_func_exit}; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   fd: %s    lfd: %s    PP: %s    (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" ${#FUNCNAME[@]} $last_funcdepth "${PPID:-\?}" "$BASHPID" "${last_command@Q}" "$cmd_type"
fi >&$fd
last_command="$BASH_COMMAND"
last_bg_pid=$!
last_pid=$BASHPID
last_funcdepth=${#FUNCNAME[@]}
' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &


( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1 )


trap - DEBUG

) {fd}>&2


:<<'EOF'

0
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3209  bp: 3209   BP: 3208  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < 'echo 0' > is a NORMAL COMMAND
1
pp: 3204   pt: 3204   cp: 3210   ct: 3210   lbp: 3209  bp: 3209   BP: 3210  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3210 > is a SUBSHELL
2
pp: 3210   pt: 3210   cp: 3210   ct: 3210   lbp: 3209  bp: 3209   BP: 3210  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3210): < 'echo 2' > is a NORMAL COMMAND
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3209  bp: 3209   BP: 3208  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < 'echo 1' > is a NORMAL COMMAND
3
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3209  bp: 3211   BP: 3208  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < 'echo 3' > is a SIMPLE FORK
4
pp: 3204   pt: 3204   cp: 3213   ct: 3214   lbp: 3211  bp: 3212   BP: 3213  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3213 > is a BACKGROUND FORK
5
pp: 3204   pt: 3204   cp: 3214   ct: 3214   lbp: 3211  bp: 3213   BP: 3214  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3214 > is a SUBSHELL
pp: 3213   pt: 3214   cp: 3213   ct: 3214   lbp: 3212  bp: 3212   BP: 3213  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3213): < 'echo 5' > is a NORMAL COMMAND
6
pp: 3214   pt: 3214   cp: 3214   ct: 3214   lbp: 3213  bp: 3215   BP: 3214  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3214): < 'echo 6' > is a SIMPLE FORK
pp: 3204   pt: 3204   cp: 3216   ct: 3217   lbp: 3211  bp: 3213   BP: 3216  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3216 > is a BACKGROUND FORK
7
pp: 3204   pt: 3204   cp: 3217   ct: 3217   lbp: 3211  bp: 3216   BP: 3217  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3217 > is a SUBSHELL
8
pp: 3216   pt: 3217   cp: 3216   ct: 3217   lbp: 3213  bp: 3213   BP: 3216  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3216): < 'echo 7' > is a NORMAL COMMAND
pp: 3217   pt: 3217   cp: 3217   ct: 3217   lbp: 3216  bp: 3216   BP: 3217  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3217): < 'echo 8' > is a NORMAL COMMAND
pp: 3204   pt: 3204   cp: 3218   ct: 3204   lbp: 3211  bp: 3216   BP: 3218  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3218 > is a BACKGROUND FORK
pp: 3204   pt: 3204   cp: 3219   ct: 3204   lbp: 3211  bp: 3218   BP: 3219  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3219 > is a BACKGROUND FORK
9.1
pp: 3204   pt: 3204   cp: 3220   ct: 3204   lbp: 3211  bp: 3219   BP: 3220  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3220 > is a BACKGROUND FORK
9
pp: 3219   pt: 3204   cp: 3219   ct: 3204   lbp: 3218  bp: 3218   BP: 3219  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3219): < 'echo 9.1' > is a NORMAL COMMAND
pp: 3204   pt: 3204   cp: 3221   ct: 3204   lbp: 3211  bp: 3220   BP: 3221  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3221 > is a BACKGROUND FORK
9.1b
pp: 3204   pt: 3204   cp: 3222   ct: 3204   lbp: 3211  bp: 3221   BP: 3222  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3222 > is a BACKGROUND FORK
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3211  bp: 3225   BP: 3208  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < 'echo 4' > is a SIMPLE FORK
pp: 3221   pt: 3204   cp: 3221   ct: 3204   lbp: 3220  bp: 3220   BP: 3221  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3221): < 'echo 9.1b' > is a NORMAL COMMAND
11
pp: 3220   pt: 3204   cp: 3220   ct: 3204   lbp: 3219  bp: 3226   BP: 3220  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3220): < 'echo 9.1a' > is a SIMPLE FORK *
pp: 3218   pt: 3204   cp: 3218   ct: 3204   lbp: 3216  bp: 3224   BP: 3218  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3218): < 'echo 9' > is a SIMPLE FORK *
9.2a
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3225  bp: 3225   BP: 3208  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < 'echo 11' > is a NORMAL COMMAND
9.2
9.1a
pp: 3220   pt: 3204   cp: 3220   ct: 3204   lbp: 3226  bp: 3226   BP: 3220  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3220): < 'echo 9.2a' > is a NORMAL COMMAND
9.2b
12
pp: 3221   pt: 3204   cp: 3221   ct: 3204   lbp: 3220  bp: 3229   BP: 3221  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3221): < 'echo 9.2b' > is a SIMPLE FORK
pp: 3219   pt: 3204   cp: 3219   ct: 3204   lbp: 3218  bp: 3227   BP: 3219  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3219): < 'echo 9.2' > is a SIMPLE FORK
9.1c
pp: 3222   pt: 3204   cp: 3222   ct: 3204   lbp: 3221  bp: 3228   BP: 3222  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3222): < 'echo 9.1c' > is a SIMPLE FORK *
9.2c
pp: 3204   pt: 3204   cp: 3223   ct: 3232   lbp: 3211  bp: 3222   BP: 3223  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3223 > is a BACKGROUND FORK
9.999
pp: 3204   pt: 3204   cp: 3225   ct: 3232   lbp: 3211  bp: 3223   BP: 3225  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3225 > is a BACKGROUND FORK
pp: 3222   pt: 3204   cp: 3222   ct: 3204   lbp: 3228  bp: 3228   BP: 3222  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3222): < 'echo 9.2c' > is a NORMAL COMMAND
pp: 3204   pt: 3204   cp: 3231   ct: 3232   lbp: 3225  bp: 3230   BP: 3231  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3231 > is a BACKGROUND FORK
pp: 3204   pt: 3204   cp: 3232   ct: 3232   lbp: 3225  bp: 3231   BP: 3232  BS: 2   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < pid: 3232 > is a SUBSHELL
13
14
pp: 3231   pt: 3232   cp: 3231   ct: 3232   lbp: 3230  bp: 3230   BP: 3231  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3231): < 'echo 13' > is a NORMAL COMMAND
10
pp: 3225   pt: 3232   cp: 3225   ct: 3232   lbp: 3223  bp: 3234   BP: 3225  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3225): < 'echo 10' > is a SIMPLE FORK
pp: 3232   pt: 3232   cp: 3232   ct: 3232   lbp: 3231  bp: 3231   BP: 3232  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3232): < 'echo 14' > is a NORMAL COMMAND
pp: 3223   pt: 3232   cp: 3223   ct: 3232   lbp: 3222  bp: 3222   BP: 3233  BS: 3   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3223): < pid: 3233 > is a SUBSHELL
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3225  bp: 3231   BP: 3208  BS: 1   lBS: 1   fd: 0    lfd: 0    PP: 3203    (3208): < 'echo 12' > is a SIMPLE FORK
9.3
pp: 3223   pt: 3232   cp: 3223   ct: 3232   lbp: 3222  bp: 3235   BP: 3233  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 3203    (3233): < 'echo 9.3' > is a SIMPLE FORK
9.4
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3231  bp: 3231   BP: 3208  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 3203    (3208): < 'ff 15' > is a FUNCTION
15
pp: 3223   pt: 3232   cp: 3223   ct: 3232   lbp: 3235  bp: 3235   BP: 3233  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 3203    (3233): < 'echo 9.4' > is a NORMAL COMMAND
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3231  bp: 3231   BP: 3208  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 3203    (3208): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 3223   pt: 3232   cp: 3223   ct: 3232   lbp: 3222  bp: 3222   BP: 3223  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3223): < 'echo 9.999' > is a NORMAL COMMAND
9.5
pp: 3223   pt: 3232   cp: 3223   ct: 3232   lbp: 3222  bp: 3222   BP: 3223  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3223): < 'echo 9.5' > is a NORMAL COMMAND
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3231  bp: 3231   BP: 3208  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 3203    (3208): < 'gg 16' > is a FUNCTION
16
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3231  bp: 3231   BP: 3208  BS: 1   lBS: 1   fd: 2    lfd: 2    PP: 3203    (3208): < 'echo "$*"' > is a NORMAL COMMAND
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3231  bp: 3231   BP: 3208  BS: 1   lBS: 1   fd: 3    lfd: 3    PP: 3203    (3208): < 'ff "$@"' > is a FUNCTION
16
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3231  bp: 3231   BP: 3208  BS: 1   lBS: 1   fd: 3    lfd: 3    PP: 3203    (3208): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 3204   pt: 3204   cp: 3236   ct: 3238   lbp: 3231  bp: 3231   BP: 3236  BS: 2   lBS: 1   fd: 0    lfd: 2    PP: 3203    (3208): < pid: 3236 > is a BACKGROUND FORK
a
pp: 3204   pt: 3204   cp: 3237   ct: 3238   lbp: 3231  bp: 3236   BP: 3239  BS: 3   lBS: 1   fd: 0    lfd: 2    PP: 3203    (3208): < pid: 3239 > is a BACKGROUND FORK
b
pp: 3236   pt: 3238   cp: 3236   ct: 3238   lbp: 3231  bp: 3241   BP: 3236  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3236): < 'echo a' > is a SIMPLE FORK
pp: 3204   pt: 3204   cp: 3238   ct: 3238   lbp: 3231  bp: 3240   BP: 3238  BS: 2   lBS: 1   fd: 0    lfd: 2    PP: 3203    (3208): < pid: 3238 > is a SUBSHELL
pp: 3237   pt: 3238   cp: 3237   ct: 3238   lbp: 3236  bp: 3236   BP: 3239  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 3203    (3239): < 'echo b' > is a NORMAL COMMAND
A2
pp: 3204   pt: 3204   cp: 3238   ct: 3238   lbp: 3231  bp: 3237   BP: 3242  BS: 4   lBS: 1   fd: 0    lfd: 2    PP: 3203    (3208): < pid: 3242 > is a SUBSHELL
pp: 3238   pt: 3238   cp: 3238   ct: 3238   lbp: 3240  bp: 3243   BP: 3238  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3238): < 'echo A2' > is a SIMPLE FORK
A1
A5
pp: 3238   pt: 3238   cp: 3238   ct: 3238   lbp: 3237  bp: 3244   BP: 3242  BS: 4   lBS: 4   fd: 0    lfd: 0    PP: 3203    (3242): < 'echo A5' > is a SIMPLE FORK
pp: 3238   pt: 3238   cp: 3238   ct: 3238   lbp: 3243  bp: 3243   BP: 3238  BS: 2   lBS: 2   fd: 0    lfd: 0    PP: 3203    (3238): < 'echo A1' > is a NORMAL COMMAND
pp: 3204   pt: 3204   cp: 3238   ct: 3204   lbp: 3231  bp: 3245   BP: 3240  BS: 3   lBS: 1   fd: 0    lfd: 2    PP: 3203    (3208): < pid: 3240 > is a BACKGROUND FORK
pp: 3204   pt: 3204   cp: 3238   ct: 3204   lbp: 3231  bp: 3237   BP: 3245  BS: 4   lBS: 1   fd: 0    lfd: 2    PP: 3203    (3208): < pid: 3245 > is a BACKGROUND FORK
A3
A4
pp: 3238   pt: 3204   cp: 3238   ct: 3204   lbp: 3245  bp: 3245   BP: 3240  BS: 3   lBS: 3   fd: 0    lfd: 0    PP: 3203    (3240): < 'echo A3' > is a NORMAL COMMAND
pp: 3238   pt: 3204   cp: 3238   ct: 3204   lbp: 3237  bp: 3237   BP: 3245  BS: 4   lBS: 4   fd: 0    lfd: 0    PP: 3203    (3245): < 'echo A4' > is a NORMAL COMMAND
pp: 3204   pt: 3204   cp: 3204   ct: 3204   lbp: 3231  bp: 3237   BP: 3208  BS: 1   lBS: 1   fd: 0    lfd: 2    PP: 3203    (3208): < 'echo "${*}"' > is a SIMPLE FORK


EOF

################################################################################


(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=()
last_funcdepth=${#FUNCNAME[@]}
last_command[$last_funcdepth]=''
subshell_pid=''
next_is_simple_fork_flag=false
this_is_simple_fork_flag=false

trap 'wait' EXIT RETURN

ff() { echo "${*}"; }
gg() { ff "$@"; }

trap 'is_bg=false
is_subshell=false
is_func=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  if (( last_bg_pid == $! )); then
    (( ${#FUNCNAME[@]} <= last_funcdepth )) || is_func=true
  else
    is_bg=true;
  fi
else
  is_subshell=true
  subshell_pid=$BASHPID 
  trap '"'"'wait'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == parent_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
  cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
elif ${is_func}; then
  cmd_type="FUNCTION"
else
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < pid: %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "${PPID:-\?}" "$last_pid" "$BASHPID" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ $last_command ]]; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "${PPID:-\?}" "$BASHPID" "${last_command@Q}" "$cmd_type"
fi >&$fd
last_command="$BASH_COMMAND"
last_bg_pid=$!
last_pid=$BASHPID
last_funcdepth=${#FUNCNAME[@]}
' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

ff 15
gg 16

( echo a & ) &
{ ( echo b ) & } &


( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1)
    
trap - DEBUG

) {fd}>&2

:<<'EOF'

0
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10319  bp: 10319   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'echo 0' > is a NORMAL COMMAND
1
pp: 10314   pt: 10314   cp: 10320   ct: 10320   lbp: 10319  bp: 10319   BP: 10320  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10320 > is a SUBSHELL
2
pp: 10320   pt: 10320   cp: 10320   ct: 10320   lbp: 10319  bp: 10319   BP: 10320  BS: 2   lBS: 2   PP: 10313    (10320): < 'echo 2' > is a NORMAL COMMAND
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10319  bp: 10319   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'echo 1' > is a NORMAL COMMAND
3
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10319  bp: 10321   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'echo 3' > is a SIMPLE FORK
4
pp: 10314   pt: 10314   cp: 10323   ct: 10324   lbp: 10321  bp: 10322   BP: 10323  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10323 > is a BACKGROUND FORK
5
pp: 10314   pt: 10314   cp: 10324   ct: 10324   lbp: 10321  bp: 10323   BP: 10324  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10324 > is a SUBSHELL
pp: 10323   pt: 10324   cp: 10323   ct: 10324   lbp: 10322  bp: 10322   BP: 10323  BS: 2   lBS: 2   PP: 10313    (10323): < 'echo 5' > is a NORMAL COMMAND
6
pp: 10324   pt: 10324   cp: 10324   ct: 10324   lbp: 10323  bp: 10325   BP: 10324  BS: 2   lBS: 2   PP: 10313    (10324): < 'echo 6' > is a SIMPLE FORK
pp: 10314   pt: 10314   cp: 10326   ct: 10327   lbp: 10321  bp: 10323   BP: 10326  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10326 > is a BACKGROUND FORK
7
pp: 10314   pt: 10314   cp: 10327   ct: 10327   lbp: 10321  bp: 10326   BP: 10327  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10327 > is a SUBSHELL
8
pp: 10326   pt: 10327   cp: 10326   ct: 10327   lbp: 10323  bp: 10323   BP: 10326  BS: 2   lBS: 2   PP: 10313    (10326): < 'echo 7' > is a NORMAL COMMAND
pp: 10327   pt: 10327   cp: 10327   ct: 10327   lbp: 10326  bp: 10326   BP: 10327  BS: 2   lBS: 2   PP: 10313    (10327): < 'echo 8' > is a NORMAL COMMAND
pp: 10314   pt: 10314   cp: 10328   ct: 10314   lbp: 10321  bp: 10326   BP: 10328  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10328 > is a BACKGROUND FORK
pp: 10314   pt: 10314   cp: 10329   ct: 10314   lbp: 10321  bp: 10328   BP: 10329  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10329 > is a BACKGROUND FORK
9.1
9
pp: 10314   pt: 10314   cp: 10330   ct: 10314   lbp: 10321  bp: 10329   BP: 10330  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10330 > is a BACKGROUND FORK
pp: 10329   pt: 10314   cp: 10329   ct: 10314   lbp: 10328  bp: 10328   BP: 10329  BS: 2   lBS: 2   PP: 10313    (10329): < 'echo 9.1' > is a NORMAL COMMAND
pp: 10328   pt: 10314   cp: 10328   ct: 10314   lbp: 10326  bp: 10333   BP: 10328  BS: 2   lBS: 2   PP: 10313    (10328): < 'echo 9' > is a SIMPLE FORK *
pp: 10314   pt: 10314   cp: 10331   ct: 10314   lbp: 10321  bp: 10330   BP: 10331  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10331 > is a BACKGROUND FORK
9.1b
pp: 10314   pt: 10314   cp: 10332   ct: 10314   lbp: 10321  bp: 10331   BP: 10332  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10332 > is a BACKGROUND FORK
9.1a
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10321  bp: 10335   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'echo 4' > is a SIMPLE FORK
pp: 10331   pt: 10314   cp: 10331   ct: 10314   lbp: 10330  bp: 10330   BP: 10331  BS: 2   lBS: 2   PP: 10313    (10331): < 'echo 9.1b' > is a NORMAL COMMAND
11
pp: 10330   pt: 10314   cp: 10330   ct: 10314   lbp: 10329  bp: 10336   BP: 10330  BS: 2   lBS: 2   PP: 10313    (10330): < 'echo 9.1a' > is a SIMPLE FORK *
pp: 10329   pt: 10314   cp: 10329   ct: 10314   lbp: 10328  bp: 10337   BP: 10329  BS: 2   lBS: 2   PP: 10313    (10329): < 'echo 9.2' > is a SIMPLE FORK
9.1c
9.2a
pp: 10314   pt: 10314   cp: 10335   ct: 10314   lbp: 10321  bp: 10334   BP: 10335  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10335 > is a BACKGROUND FORK
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10335  bp: 10335   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'echo 11' > is a NORMAL COMMAND
9.2
9.2b
pp: 10330   pt: 10314   cp: 10330   ct: 10314   lbp: 10336  bp: 10336   BP: 10330  BS: 2   lBS: 2   PP: 10313    (10330): < 'echo 9.2a' > is a NORMAL COMMAND
pp: 10332   pt: 10314   cp: 10332   ct: 10314   lbp: 10331  bp: 10338   BP: 10332  BS: 2   lBS: 2   PP: 10313    (10332): < 'echo 9.1c' > is a SIMPLE FORK *
9.2c
10
pp: 10331   pt: 10314   cp: 10331   ct: 10314   lbp: 10330  bp: 10339   BP: 10331  BS: 2   lBS: 2   PP: 10313    (10331): < 'echo 9.2b' > is a SIMPLE FORK
pp: 10332   pt: 10314   cp: 10332   ct: 10314   lbp: 10338  bp: 10338   BP: 10332  BS: 2   lBS: 2   PP: 10313    (10332): < 'echo 9.2c' > is a NORMAL COMMAND
pp: 10335   pt: 10314   cp: 10335   ct: 10314   lbp: 10334  bp: 10340   BP: 10335  BS: 2   lBS: 2   PP: 10313    (10335): < 'echo 10' > is a SIMPLE FORK *
12
pp: 10314   pt: 10314   cp: 10334   ct: 10343   lbp: 10321  bp: 10332   BP: 10334  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10334 > is a BACKGROUND FORK
9.999
pp: 10314   pt: 10314   cp: 10342   ct: 10343   lbp: 10335  bp: 10341   BP: 10342  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10342 > is a BACKGROUND FORK
13
pp: 10314   pt: 10314   cp: 10343   ct: 10343   lbp: 10335  bp: 10342   BP: 10343  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10343 > is a SUBSHELL
14
pp: 10342   pt: 10343   cp: 10342   ct: 10343   lbp: 10341  bp: 10341   BP: 10342  BS: 2   lBS: 2   PP: 10313    (10342): < 'echo 13' > is a NORMAL COMMAND
pp: 10343   pt: 10343   cp: 10343   ct: 10343   lbp: 10342  bp: 10342   BP: 10343  BS: 2   lBS: 2   PP: 10313    (10343): < 'echo 14' > is a NORMAL COMMAND
pp: 10334   pt: 10343   cp: 10334   ct: 10343   lbp: 10332  bp: 10332   BP: 10344  BS: 3   lBS: 2   PP: 10313    (10334): < pid: 10344 > is a SUBSHELL
9.3
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10335  bp: 10342   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'echo 12' > is a SIMPLE FORK
pp: 10334   pt: 10343   cp: 10334   ct: 10343   lbp: 10332  bp: 10345   BP: 10344  BS: 3   lBS: 3   PP: 10313    (10344): < 'echo 9.3' > is a SIMPLE FORK
9.4
pp: 10334   pt: 10343   cp: 10334   ct: 10343   lbp: 10345  bp: 10345   BP: 10344  BS: 3   lBS: 3   PP: 10313    (10344): < 'echo 9.4' > is a NORMAL COMMAND
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10342  bp: 10342   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'ff 15' > is a FUNCTION
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10342  bp: 10342   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'ff 15' > is a NORMAL COMMAND
15
pp: 10334   pt: 10343   cp: 10334   ct: 10343   lbp: 10332  bp: 10332   BP: 10334  BS: 2   lBS: 2   PP: 10313    (10334): < 'echo 9.999' > is a NORMAL COMMAND
9.5
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10342  bp: 10342   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 10334   pt: 10343   cp: 10334   ct: 10343   lbp: 10332  bp: 10332   BP: 10334  BS: 2   lBS: 2   PP: 10313    (10334): < 'echo 9.5' > is a NORMAL COMMAND
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10342  bp: 10342   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10342  bp: 10342   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'gg 16' > is a FUNCTION
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10342  bp: 10342   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'gg 16' > is a NORMAL COMMAND
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10342  bp: 10342   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'ff "$@"' > is a FUNCTION
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10342  bp: 10342   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'ff "$@"' > is a NORMAL COMMAND
16
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10342  bp: 10342   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10342  bp: 10342   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'echo "${*}"' > is a NORMAL COMMAND
pp: 10314   pt: 10314   cp: 10346   ct: 10348   lbp: 10342  bp: 10342   BP: 10346  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10346 > is a BACKGROUND FORK
a
pp: 10314   pt: 10314   cp: 10347   ct: 10348   lbp: 10342  bp: 10346   BP: 10349  BS: 3   lBS: 1   PP: 10313    (10318): < pid: 10349 > is a BACKGROUND FORK
b
pp: 10346   pt: 10348   cp: 10346   ct: 10348   lbp: 10342  bp: 10351   BP: 10346  BS: 2   lBS: 2   PP: 10313    (10346): < 'echo a' > is a SIMPLE FORK
pp: 10314   pt: 10314   cp: 10348   ct: 10348   lbp: 10342  bp: 10350   BP: 10348  BS: 2   lBS: 1   PP: 10313    (10318): < pid: 10348 > is a SUBSHELL
pp: 10347   pt: 10348   cp: 10347   ct: 10348   lbp: 10346  bp: 10346   BP: 10349  BS: 3   lBS: 3   PP: 10313    (10349): < 'echo b' > is a NORMAL COMMAND
pp: 10314   pt: 10314   cp: 10348   ct: 10348   lbp: 10342  bp: 10347   BP: 10352  BS: 4   lBS: 1   PP: 10313    (10318): < pid: 10352 > is a SUBSHELL
A2
pp: 10348   pt: 10348   cp: 10348   ct: 10348   lbp: 10350  bp: 10353   BP: 10348  BS: 2   lBS: 2   PP: 10313    (10348): < 'echo A2' > is a SIMPLE FORK
A1
A5
pp: 10348   pt: 10348   cp: 10348   ct: 10348   lbp: 10353  bp: 10353   BP: 10348  BS: 2   lBS: 2   PP: 10313    (10348): < 'echo A1' > is a NORMAL COMMAND
pp: 10348   pt: 10348   cp: 10348   ct: 10348   lbp: 10347  bp: 10354   BP: 10352  BS: 4   lBS: 4   PP: 10313    (10352): < 'echo A5' > is a SIMPLE FORK
pp: 10314   pt: 10314   cp: 10348   ct: 10314   lbp: 10342  bp: 10355   BP: 10350  BS: 3   lBS: 1   PP: 10313    (10318): < pid: 10350 > is a BACKGROUND FORK
A3
pp: 10314   pt: 10314   cp: 10348   ct: 10314   lbp: 10342  bp: 10347   BP: 10355  BS: 4   lBS: 1   PP: 10313    (10318): < pid: 10355 > is a BACKGROUND FORK
A4
pp: 10348   pt: 10314   cp: 10348   ct: 10314   lbp: 10355  bp: 10355   BP: 10350  BS: 3   lBS: 3   PP: 10313    (10350): < 'echo A3' > is a NORMAL COMMAND
pp: 10348   pt: 10314   cp: 10348   ct: 10314   lbp: 10347  bp: 10347   BP: 10355  BS: 4   lBS: 4   PP: 10313    (10355): < 'echo A4' > is a NORMAL COMMAND
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10342  bp: 10347   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < 'echo "${*}"' > is a SIMPLE FORK
pp: 10314   pt: 10314   cp: 10314   ct: 10314   lbp: 10347  bp: 10347   BP: 10318  BS: 1   lBS: 1   PP: 10313    (10318): < ':' > is a NORMAL COMMAND



EOF









##################################################

(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=''
subshell_pid=''
next_is_simple_fork_flag=false
this_is_simple_fork_flag=false

trap 'wait' EXIT

trap 'is_bg=false
is_subshell=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  (( last_bg_pid == $! )) || is_bg=true;
else
  is_subshell=true
  subshell_pid=$BASHPID 
  trap '"'"'wait'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == child_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
    cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
else
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < pid: %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "${PPID:-\?}" "$last_pid" "$BASHPID" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ $last_command ]]; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "${PPID:-\?}" "$BASHPID" "${last_command@Q}" "$cmd_type"
fi >&$fd
last_command="$BASH_COMMAND"
last_bg_pid=$!
last_pid=$BASHPID
' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

( echo a & ) &
{ ( echo b ) & } &


( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1)

trap - DEBUG

) {fd}>&2


:<<'EOF'

0
pp: 15   pt: 15   cp: 15   ct: 15   lbp: 20  bp: 20   BP: 19  BS: 1   lBS: 1   PP: 14    (19): < 'echo 0' > is a NORMAL COMMAND
1
pp: 15   pt: 15   cp: 21   ct: 21   lbp: 20  bp: 20   BP: 21  BS: 2   lBS: 1   PP: 14    (19): < pid: 21 > is a SUBSHELL
2
pp: 21   pt: 21   cp: 21   ct: 21   lbp: 20  bp: 20   BP: 21  BS: 2   lBS: 2   PP: 14    (21): < 'echo 2' > is a NORMAL COMMAND
pp: 15   pt: 15   cp: 15   ct: 15   lbp: 20  bp: 20   BP: 19  BS: 1   lBS: 1   PP: 14    (19): < 'echo 1' > is a NORMAL COMMAND
3
pp: 15   pt: 15   cp: 15   ct: 15   lbp: 20  bp: 22   BP: 19  BS: 1   lBS: 1   PP: 14    (19): < 'echo 3' > is a SIMPLE FORK
4
pp: 15   pt: 15   cp: 24   ct: 25   lbp: 22  bp: 23   BP: 24  BS: 2   lBS: 1   PP: 14    (19): < pid: 24 > is a BACKGROUND FORK
5
pp: 15   pt: 15   cp: 25   ct: 25   lbp: 22  bp: 24   BP: 25  BS: 2   lBS: 1   PP: 14    (19): < pid: 25 > is a SUBSHELL
pp: 24   pt: 25   cp: 24   ct: 25   lbp: 23  bp: 23   BP: 24  BS: 2   lBS: 2   PP: 14    (24): < 'echo 5' > is a NORMAL COMMAND
6
pp: 25   pt: 25   cp: 25   ct: 25   lbp: 24  bp: 26   BP: 25  BS: 2   lBS: 2   PP: 14    (25): < 'echo 6' > is a SIMPLE FORK
pp: 15   pt: 15   cp: 27   ct: 28   lbp: 22  bp: 24   BP: 27  BS: 2   lBS: 1   PP: 14    (19): < pid: 27 > is a BACKGROUND FORK
7
pp: 15   pt: 15   cp: 28   ct: 28   lbp: 22  bp: 27   BP: 28  BS: 2   lBS: 1   PP: 14    (19): < pid: 28 > is a SUBSHELL
8
pp: 27   pt: 28   cp: 27   ct: 28   lbp: 24  bp: 24   BP: 27  BS: 2   lBS: 2   PP: 14    (27): < 'echo 7' > is a NORMAL COMMAND
pp: 28   pt: 28   cp: 28   ct: 28   lbp: 27  bp: 27   BP: 28  BS: 2   lBS: 2   PP: 14    (28): < 'echo 8' > is a NORMAL COMMAND
pp: 15   pt: 15   cp: 29   ct: 15   lbp: 22  bp: 27   BP: 29  BS: 2   lBS: 1   PP: 14    (19): < pid: 29 > is a BACKGROUND FORK
pp: 15   pt: 15   cp: 30   ct: 15   lbp: 22  bp: 29   BP: 30  BS: 2   lBS: 1   PP: 14    (19): < pid: 30 > is a BACKGROUND FORK
9.1
pp: 15   pt: 15   cp: 31   ct: 15   lbp: 22  bp: 30   BP: 31  BS: 2   lBS: 1   PP: 14    (19): < pid: 31 > is a BACKGROUND FORK
9
pp: 30   pt: 15   cp: 30   ct: 15   lbp: 29  bp: 29   BP: 30  BS: 2   lBS: 2   PP: 14    (30): < 'echo 9.1' > is a NORMAL COMMAND
pp: 15   pt: 15   cp: 32   ct: 15   lbp: 22  bp: 31   BP: 32  BS: 2   lBS: 1   PP: 14    (19): < pid: 32 > is a BACKGROUND FORK
pp: 29   pt: 15   cp: 29   ct: 15   lbp: 27  bp: 34   BP: 29  BS: 2   lBS: 2   PP: 14    (29): < 'echo 9' > is a SIMPLE FORK *
9.1b
pp: 15   pt: 15   cp: 33   ct: 15   lbp: 22  bp: 32   BP: 33  BS: 2   lBS: 1   PP: 14    (19): < pid: 33 > is a BACKGROUND FORK
pp: 15   pt: 15   cp: 15   ct: 15   lbp: 22  bp: 36   BP: 19  BS: 1   lBS: 1   PP: 14    (19): < 'echo 4' > is a SIMPLE FORK
pp: 31   pt: 15   cp: 31   ct: 15   lbp: 30  bp: 37   BP: 31  BS: 2   lBS: 2   PP: 14    (31): < 'echo 9.1a' > is a SIMPLE FORK *
pp: 32   pt: 15   cp: 32   ct: 15   lbp: 31  bp: 31   BP: 32  BS: 2   lBS: 2   PP: 14    (32): < 'echo 9.1b' > is a NORMAL COMMAND
11
9.2a
pp: 31   pt: 15   cp: 31   ct: 15   lbp: 37  bp: 37   BP: 31  BS: 2   lBS: 2   PP: 14    (31): < 'echo 9.2a' > is a NORMAL COMMAND
pp: 15   pt: 15   cp: 15   ct: 15   lbp: 36  bp: 36   BP: 19  BS: 1   lBS: 1   PP: 14    (19): < 'echo 11' > is a NORMAL COMMAND
pp: 30   pt: 15   cp: 30   ct: 15   lbp: 29  bp: 38   BP: 30  BS: 2   lBS: 2   PP: 14    (30): < 'echo 9.2' > is a SIMPLE FORK
pp: 33   pt: 15   cp: 33   ct: 15   lbp: 32  bp: 39   BP: 33  BS: 2   lBS: 2   PP: 14    (33): < 'echo 9.1c' > is a SIMPLE FORK *
pp: 15   pt: 15   cp: 35   ct: 15   lbp: 22  bp: 33   BP: 35  BS: 2   lBS: 1   PP: 14    (19): < pid: 35 > is a BACKGROUND FORK
9.1a
9.2c
9.999
9.2
pp: 15   pt: 15   cp: 36   ct: 15   lbp: 22  bp: 35   BP: 36  BS: 2   lBS: 1   PP: 14    (19): < pid: 36 > is a BACKGROUND FORK
pp: 32   pt: 15   cp: 32   ct: 15   lbp: 31  bp: 40   BP: 32  BS: 2   lBS: 2   PP: 14    (32): < 'echo 9.2b' > is a SIMPLE FORK
pp: 33   pt: 15   cp: 33   ct: 15   lbp: 39  bp: 39   BP: 33  BS: 2   lBS: 2   PP: 14    (33): < 'echo 9.2c' > is a NORMAL COMMAND
9.2b
9.1c
10
12
pp: 36   pt: 15   cp: 36   ct: 15   lbp: 35  bp: 44   BP: 36  BS: 2   lBS: 2   PP: 14    (36): < 'echo 10' > is a SIMPLE FORK *
pp: 35   pt: 15   cp: 35   ct: 45   lbp: 33  bp: 33   BP: 42  BS: 3   lBS: 2   PP: 14    (35): < pid: 42 > is a SUBSHELL
pp: 15   pt: 15   cp: 43   ct: 45   lbp: 36  bp: 41   BP: 43  BS: 2   lBS: 1   PP: 14    (19): < pid: 43 > is a BACKGROUND FORK
13
pp: 15   pt: 15   cp: 45   ct: 45   lbp: 36  bp: 43   BP: 45  BS: 2   lBS: 1   PP: 14    (19): < pid: 45 > is a SUBSHELL
14
pp: 43   pt: 45   cp: 43   ct: 45   lbp: 41  bp: 41   BP: 43  BS: 2   lBS: 2   PP: 14    (43): < 'echo 13' > is a NORMAL COMMAND
pp: 45   pt: 45   cp: 45   ct: 45   lbp: 43  bp: 43   BP: 45  BS: 2   lBS: 2   PP: 14    (45): < 'echo 14' > is a NORMAL COMMAND
9.3
pp: 35   pt: 45   cp: 35   ct: 45   lbp: 33  bp: 46   BP: 42  BS: 3   lBS: 3   PP: 14    (42): < 'echo 9.3' > is a SIMPLE FORK
9.4
pp: 35   pt: 45   cp: 35   ct: 45   lbp: 46  bp: 46   BP: 42  BS: 3   lBS: 3   PP: 14    (42): < 'echo 9.4' > is a NORMAL COMMAND
pp: 15   pt: 15   cp: 47   ct: 49   lbp: 36  bp: 43   BP: 47  BS: 2   lBS: 1   PP: 14    (19): < pid: 47 > is a BACKGROUND FORK
pp: 35   pt: 15   cp: 35   ct: 15   lbp: 33  bp: 33   BP: 35  BS: 2   lBS: 2   PP: 14    (35): < 'echo 9.999' > is a NORMAL COMMAND
9.5
pp: 35   pt: 15   cp: 35   ct: 15   lbp: 33  bp: 33   BP: 35  BS: 2   lBS: 2   PP: 14    (35): < 'echo 9.5' > is a NORMAL COMMAND
a
pp: 15   pt: 15   cp: 48   ct: 49   lbp: 36  bp: 47   BP: 50  BS: 3   lBS: 1   PP: 14    (19): < pid: 50 > is a BACKGROUND FORK
pp: 15   pt: 15   cp: 49   ct: 49   lbp: 36  bp: 51   BP: 49  BS: 2   lBS: 1   PP: 14    (19): < pid: 49 > is a SUBSHELL
b
pp: 47   pt: 49   cp: 47   ct: 49   lbp: 43  bp: 52   BP: 47  BS: 2   lBS: 2   PP: 14    (47): < 'echo a' > is a SIMPLE FORK
pp: 48   pt: 49   cp: 48   ct: 49   lbp: 47  bp: 47   BP: 50  BS: 3   lBS: 3   PP: 14    (50): < 'echo b' > is a NORMAL COMMAND
A2
pp: 15   pt: 15   cp: 49   ct: 49   lbp: 36  bp: 48   BP: 53  BS: 4   lBS: 1   PP: 14    (19): < pid: 53 > is a SUBSHELL
pp: 49   pt: 49   cp: 49   ct: 49   lbp: 51  bp: 54   BP: 49  BS: 2   lBS: 2   PP: 14    (49): < 'echo A2' > is a SIMPLE FORK
A1
A5
pp: 49   pt: 49   cp: 49   ct: 49   lbp: 54  bp: 54   BP: 49  BS: 2   lBS: 2   PP: 14    (49): < 'echo A1' > is a NORMAL COMMAND
pp: 49   pt: 49   cp: 49   ct: 49   lbp: 48  bp: 55   BP: 53  BS: 4   lBS: 4   PP: 14    (53): < 'echo A5' > is a SIMPLE FORK
pp: 15   pt: 15   cp: 49   ct: 15   lbp: 36  bp: 56   BP: 51  BS: 3   lBS: 1   PP: 14    (19): < pid: 51 > is a BACKGROUND FORK
A3
pp: 15   pt: 15   cp: 49   ct: 15   lbp: 36  bp: 48   BP: 56  BS: 4   lBS: 1   PP: 14    (19): < pid: 56 > is a BACKGROUND FORK
pp: 49   pt: 15   cp: 49   ct: 15   lbp: 56  bp: 56   BP: 51  BS: 3   lBS: 3   PP: 14    (51): < 'echo A3' > is a NORMAL COMMAND
A4
pp: 49   pt: 15   cp: 49   ct: 15   lbp: 48  bp: 48   BP: 56  BS: 4   lBS: 4   PP: 14    (56): < 'echo A4' > is a NORMAL COMMAND
pp: 15   pt: 15   cp: 15   ct: 15   lbp: 36  bp: 48   BP: 19  BS: 1   lBS: 1   PP: 14    (19): < 'echo 12' > is a SIMPLE FORK

EOF







(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &

last_pid=$BASHPID
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=''
subshell_pid=''
next_is_simple_fork_flag=false
this_is_simple_fork_flag=false

trap 'wait' EXIT

trap 'is_bg=false
is_subshell=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  (( last_bg_pid == $! )) || is_bg=true;
else
  is_subshell=true
  subshell_pid=$BASHPID 
  trap '"'"'wait'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == child_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
    cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
else
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < pid: %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "${PPID:-\?}" "$last_pid" "$BASHPID" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ $last_command ]]; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "${PPID:-\?}" "$BASHPID" "${last_command@Q}" "$cmd_type"
fi >&$fd
last_command="$BASH_COMMAND"
last_bg_pid=$!
last_pid=$BASHPID
unset cmd_type
' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
( echo 9.1b; echo 9.2b & ) &
( echo 9.1c & echo 9.2c; ) &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

( echo a & ) &
{ ( echo b ) & } &


( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1)

trap - DEBUG

) {fd}>&2


:<'EOF'

0
pp: 6388   pt: 6388   cp: 6388   ct: 6388   lbp: 6393  bp: 6393   BP: 6392  BS: 1   lBS: 1   PP: 6387    (6392): < 'echo 0' > is a NORMAL COMMAND
1
pp: 6388   pt: 6388   cp: 6394   ct: 6394   lbp: 6393  bp: 6393   BP: 6394  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6394 > is a SUBSHELL
2
pp: 6394   pt: 6394   cp: 6394   ct: 6394   lbp: 6393  bp: 6393   BP: 6394  BS: 2   lBS: 2   PP: 6387    (6394): < 'echo 2' > is a NORMAL COMMAND
pp: 6388   pt: 6388   cp: 6388   ct: 6388   lbp: 6393  bp: 6393   BP: 6392  BS: 1   lBS: 1   PP: 6387    (6392): < 'echo 1' > is a NORMAL COMMAND
3
pp: 6388   pt: 6388   cp: 6388   ct: 6388   lbp: 6393  bp: 6395   BP: 6392  BS: 1   lBS: 1   PP: 6387    (6392): < 'echo 3' > is a SIMPLE FORK
4
pp: 6388   pt: 6388   cp: 6397   ct: 6398   lbp: 6395  bp: 6396   BP: 6397  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6397 > is a BACKGROUND FORK
5
pp: 6397   pt: 6398   cp: 6397   ct: 6398   lbp: 6396  bp: 6396   BP: 6397  BS: 2   lBS: 2   PP: 6387    (6397): < 'echo 5' > is a NORMAL COMMAND
pp: 6388   pt: 6388   cp: 6398   ct: 6398   lbp: 6395  bp: 6397   BP: 6398  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6398 > is a SUBSHELL
6
pp: 6398   pt: 6398   cp: 6398   ct: 6398   lbp: 6397  bp: 6399   BP: 6398  BS: 2   lBS: 2   PP: 6387    (6398): < 'echo 6' > is a SIMPLE FORK
pp: 6388   pt: 6388   cp: 6400   ct: 6401   lbp: 6395  bp: 6397   BP: 6400  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6400 > is a BACKGROUND FORK
pp: 6388   pt: 6388   cp: 6401   ct: 6401   lbp: 6395  bp: 6400   BP: 6401  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6401 > is a SUBSHELL
8
7
pp: 6401   pt: 6401   cp: 6401   ct: 6401   lbp: 6400  bp: 6400   BP: 6401  BS: 2   lBS: 2   PP: 6387    (6401): < 'echo 8' > is a NORMAL COMMAND
pp: 6400   pt: 6401   cp: 6400   ct: 6401   lbp: 6397  bp: 6397   BP: 6400  BS: 2   lBS: 2   PP: 6387    (6400): < 'echo 7' > is a NORMAL COMMAND
pp: 6388   pt: 6388   cp: 6403   ct: 6388   lbp: 6395  bp: 6402   BP: 6403  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6403 > is a BACKGROUND FORK
pp: 6388   pt: 6388   cp: 6402   ct: 6388   lbp: 6395  bp: 6400   BP: 6402  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6402 > is a BACKGROUND FORK
9.1
pp: 6388   pt: 6388   cp: 6404   ct: 6388   lbp: 6395  bp: 6403   BP: 6404  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6404 > is a BACKGROUND FORK
pp: 6403   pt: 6388   cp: 6403   ct: 6388   lbp: 6402  bp: 6402   BP: 6403  BS: 2   lBS: 2   PP: 6387    (6403): < 'echo 9.1' > is a NORMAL COMMAND
pp: 6388   pt: 6388   cp: 6405   ct: 6388   lbp: 6395  bp: 6404   BP: 6405  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6405 > is a BACKGROUND FORK
9.1b
pp: 6405   pt: 6388   cp: 6405   ct: 6388   lbp: 6404  bp: 6404   BP: 6405  BS: 2   lBS: 2   PP: 6387    (6405): < 'echo 9.1b' > is a NORMAL COMMAND
pp: 6388   pt: 6388   cp: 6406   ct: 6388   lbp: 6395  bp: 6405   BP: 6406  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6406 > is a BACKGROUND FORK
pp: 6402   pt: 6388   cp: 6402   ct: 6388   lbp: 6400  bp: 6408   BP: 6402  BS: 2   lBS: 2   PP: 6387    (6402): < 'echo 9' > is a SIMPLE FORK *
pp: 6404   pt: 6388   cp: 6404   ct: 6388   lbp: 6403  bp: 6410   BP: 6404  BS: 2   lBS: 2   PP: 6387    (6404): < 'echo 9.1a' > is a SIMPLE FORK *
pp: 6388   pt: 6388   cp: 6407   ct: 6388   lbp: 6395  bp: 6406   BP: 6407  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6407 > is a BACKGROUND FORK
9.2a
9.999
pp: 6403   pt: 6388   cp: 6403   ct: 6388   lbp: 6402  bp: 6411   BP: 6403  BS: 2   lBS: 2   PP: 6387    (6403): < 'echo 9.2' > is a SIMPLE FORK
9.2b
pp: 6404   pt: 6388   cp: 6404   ct: 6388   lbp: 6410  bp: 6410   BP: 6404  BS: 2   lBS: 2   PP: 6387    (6404): < 'echo 9.2a' > is a NORMAL COMMAND
pp: 6405   pt: 6388   cp: 6405   ct: 6388   lbp: 6404  bp: 6412   BP: 6405  BS: 2   lBS: 2   PP: 6387    (6405): < 'echo 9.2b' > is a SIMPLE FORK
9.1c
pp: 6388   pt: 6388   cp: 6388   ct: 6388   lbp: 6395  bp: 6409   BP: 6392  BS: 1   lBS: 1   PP: 6387    (6392): < 'echo 4' > is a SIMPLE FORK
pp: 6388   pt: 6388   cp: 6409   ct: 6388   lbp: 6395  bp: 6407   BP: 6409  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6409 > is a BACKGROUND FORK
11
pp: 6406   pt: 6388   cp: 6406   ct: 6388   lbp: 6405  bp: 6413   BP: 6406  BS: 2   lBS: 2   PP: 6387    (6406): < 'echo 9.1c' > is a SIMPLE FORK *
9.2c
pp: 6388   pt: 6388   cp: 6388   ct: 6388   lbp: 6409  bp: 6409   BP: 6392  BS: 1   lBS: 1   PP: 6387    (6392): < 'echo 11' > is a NORMAL COMMAND
pp: 6406   pt: 6388   cp: 6406   ct: 6388   lbp: 6413  bp: 6413   BP: 6406  BS: 2   lBS: 2   PP: 6387    (6406): < 'echo 9.2c' > is a NORMAL COMMAND
9.2
10
9
pp: 6409   pt: 6388   cp: 6409   ct: 6388   lbp: 6407  bp: 6415   BP: 6409  BS: 2   lBS: 2   PP: 6387    (6409): < 'echo 10' > is a SIMPLE FORK *
pp: 6407   pt: 6388   cp: 6407   ct: 6388   lbp: 6406  bp: 6406   BP: 6414  BS: 3   lBS: 2   PP: 6387    (6407): < pid: 6414 > is a SUBSHELL
12
9.1a
9.3
pp: 6388   pt: 6388   cp: 6418   ct: 6418   lbp: 6409  bp: 6417   BP: 6418  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6418 > is a SUBSHELL
14
pp: 6388   pt: 6388   cp: 6417   ct: 6418   lbp: 6409  bp: 6416   BP: 6417  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6417 > is a BACKGROUND FORK
13
pp: 6407   pt: 6388   cp: 6407   ct: 6388   lbp: 6406  bp: 6419   BP: 6414  BS: 3   lBS: 3   PP: 6387    (6414): < 'echo 9.3' > is a SIMPLE FORK
9.4
pp: 6418   pt: 6418   cp: 6418   ct: 6418   lbp: 6417  bp: 6417   BP: 6418  BS: 2   lBS: 2   PP: 6387    (6418): < 'echo 14' > is a NORMAL COMMAND
pp: 6417   pt: 6418   cp: 6417   ct: 6418   lbp: 6416  bp: 6416   BP: 6417  BS: 2   lBS: 2   PP: 6387    (6417): < 'echo 13' > is a NORMAL COMMAND
pp: 6407   pt: 6388   cp: 6407   ct: 6388   lbp: 6419  bp: 6419   BP: 6414  BS: 3   lBS: 3   PP: 6387    (6414): < 'echo 9.4' > is a NORMAL COMMAND
pp: 6407   pt: 6388   cp: 6407   ct: 6388   lbp: 6406  bp: 6406   BP: 6407  BS: 2   lBS: 2   PP: 6387    (6407): < 'echo 9.999' > is a NORMAL COMMAND
9.5
pp: 6407   pt: 6388   cp: 6407   ct: 6388   lbp: 6406  bp: 6406   BP: 6407  BS: 2   lBS: 2   PP: 6387    (6407): < 'echo 9.5' > is a NORMAL COMMAND
pp: 6388   pt: 6388   cp: 6420   ct: 6422   lbp: 6409  bp: 6417   BP: 6420  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6420 > is a BACKGROUND FORK
a
pp: 6388   pt: 6388   cp: 6422   ct: 6422   lbp: 6409  bp: 6424   BP: 6422  BS: 2   lBS: 1   PP: 6387    (6392): < pid: 6422 > is a SUBSHELL
pp: 6388   pt: 6388   cp: 6421   ct: 6422   lbp: 6409  bp: 6420   BP: 6423  BS: 3   lBS: 1   PP: 6387    (6392): < pid: 6423 > is a BACKGROUND FORK
pp: 6420   pt: 6422   cp: 6420   ct: 6422   lbp: 6417  bp: 6425   BP: 6420  BS: 2   lBS: 2   PP: 6387    (6420): < 'echo a' > is a SIMPLE FORK
b
pp: 6388   pt: 6388   cp: 6422   ct: 6422   lbp: 6409  bp: 6421   BP: 6426  BS: 4   lBS: 1   PP: 6387    (6392): < pid: 6426 > is a SUBSHELL
pp: 6421   pt: 6422   cp: 6421   ct: 6422   lbp: 6420  bp: 6420   BP: 6423  BS: 3   lBS: 3   PP: 6387    (6423): < 'echo b' > is a NORMAL COMMAND
A2
pp: 6422   pt: 6422   cp: 6422   ct: 6422   lbp: 6424  bp: 6427   BP: 6422  BS: 2   lBS: 2   PP: 6387    (6422): < 'echo A2' > is a SIMPLE FORK
A1
A5
pp: 6422   pt: 6422   cp: 6422   ct: 6422   lbp: 6421  bp: 6428   BP: 6426  BS: 4   lBS: 4   PP: 6387    (6426): < 'echo A5' > is a SIMPLE FORK
pp: 6422   pt: 6422   cp: 6422   ct: 6422   lbp: 6427  bp: 6427   BP: 6422  BS: 2   lBS: 2   PP: 6387    (6422): < 'echo A1' > is a NORMAL COMMAND
pp: 6388   pt: 6388   cp: 6422   ct: 6388   lbp: 6409  bp: 6429   BP: 6424  BS: 3   lBS: 1   PP: 6387    (6392): < pid: 6424 > is a BACKGROUND FORK
A3
pp: 6388   pt: 6388   cp: 6422   ct: 6388   lbp: 6409  bp: 6421   BP: 6429  BS: 4   lBS: 1   PP: 6387    (6392): < pid: 6429 > is a BACKGROUND FORK
A4
pp: 6422   pt: 6388   cp: 6422   ct: 6388   lbp: 6429  bp: 6429   BP: 6424  BS: 3   lBS: 3   PP: 6387    (6424): < 'echo A3' > is a NORMAL COMMAND
pp: 6422   pt: 6388   cp: 6422   ct: 6388   lbp: 6421  bp: 6421   BP: 6429  BS: 4   lBS: 4   PP: 6387    (6429): < 'echo A4' > is a NORMAL COMMAND
pp: 6388   pt: 6388   cp: 6388   ct: 6388   lbp: 6409  bp: 6421   BP: 6392  BS: 1   lBS: 1   PP: 6387    (6392): < 'echo 12' > is a SIMPLE FORK


EOF



######################################################


(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=''
subshell_pid=''
next_is_simple_fork_flag=false
this_is_simple_fork_flag=false

trap 'wait' EXIT

trap 'is_bg=false
is_subshell=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  (( last_bg_pid == $! )) || is_bg=true;
else
  is_subshell=true
  subshell_pid=$BASHPID 
  trap '"'"'wait'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || {  (( child_pgid == parent_pgid )) && (( child_tpid == child_tpid )); } || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
    cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
else
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    < pid: %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "${PPID:-\?}" "$BASHPID" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ $last_command ]]; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "${PPID:-\?}" "$BASHPID" "${last_command@Q}" "$cmd_type"
fi >&$fd
last_command="$BASH_COMMAND"
last_bg_pid=$!
unset cmd_type
' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; echo 9.2 & } &
{ echo 9.1a & echo 9.2a; } &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

( echo a & ) &
{ ( echo b ) & } &


( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1)

trap - DEBUG

) {fd}>&2

:<<'EOF'

0
pp: 1924   pt: 1924   cp: 1924   ct: 1924   lbp: 1929  bp: 1929   BP: 1928  BS: 1   lBS: 1   PP: 1923    (1928): < 'echo 0' > is a NORMAL COMMAND
1
pp: 1924   pt: 1924   cp: 1930   ct: 1930   lbp: 1929  bp: 1929   BP: 1930  BS: 2   lBS: 1   PP: 1923    < pid: 1930 > is a SUBSHELL
2
pp: 1930   pt: 1930   cp: 1930   ct: 1930   lbp: 1929  bp: 1929   BP: 1930  BS: 2   lBS: 2   PP: 1923    (1930): < 'echo 2' > is a NORMAL COMMAND
pp: 1924   pt: 1924   cp: 1924   ct: 1924   lbp: 1929  bp: 1929   BP: 1928  BS: 1   lBS: 1   PP: 1923    (1928): < 'echo 1' > is a NORMAL COMMAND
3
pp: 1924   pt: 1924   cp: 1924   ct: 1924   lbp: 1929  bp: 1931   BP: 1928  BS: 1   lBS: 1   PP: 1923    (1928): < 'echo 3' > is a SIMPLE FORK
4
pp: 1924   pt: 1924   cp: 1933   ct: 1934   lbp: 1931  bp: 1932   BP: 1933  BS: 2   lBS: 1   PP: 1923    < pid: 1933 > is a BACKGROUND FORK
5
pp: 1924   pt: 1924   cp: 1934   ct: 1934   lbp: 1931  bp: 1933   BP: 1934  BS: 2   lBS: 1   PP: 1923    < pid: 1934 > is a SUBSHELL
pp: 1933   pt: 1934   cp: 1933   ct: 1934   lbp: 1932  bp: 1932   BP: 1933  BS: 2   lBS: 2   PP: 1923    (1933): < 'echo 5' > is a NORMAL COMMAND
6
pp: 1934   pt: 1934   cp: 1934   ct: 1934   lbp: 1933  bp: 1935   BP: 1934  BS: 2   lBS: 2   PP: 1923    (1934): < 'echo 6' > is a SIMPLE FORK
pp: 1924   pt: 1924   cp: 1936   ct: 1937   lbp: 1931  bp: 1933   BP: 1936  BS: 2   lBS: 1   PP: 1923    < pid: 1936 > is a BACKGROUND FORK
7
pp: 1924   pt: 1924   cp: 1937   ct: 1937   lbp: 1931  bp: 1936   BP: 1937  BS: 2   lBS: 1   PP: 1923    < pid: 1937 > is a SUBSHELL
8
pp: 1936   pt: 1937   cp: 1936   ct: 1937   lbp: 1933  bp: 1933   BP: 1936  BS: 2   lBS: 2   PP: 1923    (1936): < 'echo 7' > is a NORMAL COMMAND
pp: 1937   pt: 1937   cp: 1937   ct: 1937   lbp: 1936  bp: 1936   BP: 1937  BS: 2   lBS: 2   PP: 1923    (1937): < 'echo 8' > is a NORMAL COMMAND
pp: 1924   pt: 1924   cp: 1938   ct: 1924   lbp: 1931  bp: 1936   BP: 1938  BS: 2   lBS: 1   PP: 1923    < pid: 1938 > is a BACKGROUND FORK
pp: 1924   pt: 1924   cp: 1939   ct: 1924   lbp: 1931  bp: 1938   BP: 1939  BS: 2   lBS: 1   PP: 1923    < pid: 1939 > is a BACKGROUND FORK
9.1
pp: 1924   pt: 1924   cp: 1940   ct: 1924   lbp: 1931  bp: 1939   BP: 1940  BS: 2   lBS: 1   PP: 1923    < pid: 1940 > is a BACKGROUND FORK
pp: 1939   pt: 1924   cp: 1939   ct: 1924   lbp: 1938  bp: 1938   BP: 1939  BS: 2   lBS: 2   PP: 1923    (1939): < 'echo 9.1' > is a NORMAL COMMAND
pp: 1938   pt: 1924   cp: 1938   ct: 1924   lbp: 1936  bp: 1942   BP: 1938  BS: 2   lBS: 2   PP: 1923    (1938): < 'echo 9' > is a SIMPLE FORK *
pp: 1924   pt: 1924   cp: 1924   ct: 1924   lbp: 1931  bp: 1943   BP: 1928  BS: 1   lBS: 1   PP: 1923    (1928): < 'echo 4' > is a SIMPLE FORK
11
9
pp: 1924   pt: 1924   cp: 1941   ct: 1924   lbp: 1931  bp: 1940   BP: 1941  BS: 2   lBS: 1   PP: 1923    < pid: 1941 > is a BACKGROUND FORK
pp: 1924   pt: 1924   cp: 1924   ct: 1924   lbp: 1943  bp: 1943   BP: 1928  BS: 1   lBS: 1   PP: 1923    (1928): < 'echo 11' > is a NORMAL COMMAND
9.999
pp: 1924   pt: 1924   cp: 1943   ct: 1924   lbp: 1931  bp: 1941   BP: 1943  BS: 2   lBS: 1   PP: 1923    < pid: 1943 > is a BACKGROUND FORK
pp: 1940   pt: 1924   cp: 1940   ct: 1924   lbp: 1939  bp: 1944   BP: 1940  BS: 2   lBS: 2   PP: 1923    (1940): < 'echo 9.1a' > is a SIMPLE FORK *
9.2a
pp: 1939   pt: 1924   cp: 1939   ct: 1924   lbp: 1938  bp: 1945   BP: 1939  BS: 2   lBS: 2   PP: 1923    (1939): < 'echo 9.2' > is a SIMPLE FORK
9.1a
pp: 1940   pt: 1924   cp: 1940   ct: 1924   lbp: 1944  bp: 1944   BP: 1940  BS: 2   lBS: 2   PP: 1923    (1940): < 'echo 9.2a' > is a NORMAL COMMAND
9.2
12
pp: 1943   pt: 1924   cp: 1943   ct: 1924   lbp: 1941  bp: 1948   BP: 1943  BS: 2   lBS: 2   PP: 1923    (1943): < 'echo 10' > is a SIMPLE FORK *
10
pp: 1941   pt: 1924   cp: 1941   ct: 1924   lbp: 1940  bp: 1940   BP: 1946  BS: 3   lBS: 2   PP: 1923    < pid: 1946 > is a SUBSHELL
pp: 1924   pt: 1924   cp: 1949   ct: 1950   lbp: 1943  bp: 1947   BP: 1949  BS: 2   lBS: 1   PP: 1923    < pid: 1949 > is a BACKGROUND FORK
13
pp: 1949   pt: 1950   cp: 1949   ct: 1950   lbp: 1947  bp: 1947   BP: 1949  BS: 2   lBS: 2   PP: 1923    (1949): < 'echo 13' > is a NORMAL COMMAND
9.3
pp: 1924   pt: 1924   cp: 1950   ct: 1941   lbp: 1943  bp: 1949   BP: 1950  BS: 2   lBS: 1   PP: 1923    < pid: 1950 > is a BACKGROUND FORK
14
pp: 1941   pt: 1924   cp: 1941   ct: 1924   lbp: 1940  bp: 1951   BP: 1946  BS: 3   lBS: 3   PP: 1923    (1946): < 'echo 9.3' > is a SIMPLE FORK
9.4
pp: 1941   pt: 1924   cp: 1941   ct: 1924   lbp: 1951  bp: 1951   BP: 1946  BS: 3   lBS: 3   PP: 1923    (1946): < 'echo 9.4' > is a NORMAL COMMAND
pp: 1950   pt: 1941   cp: 1950   ct: 1941   lbp: 1949  bp: 1949   BP: 1950  BS: 2   lBS: 2   PP: 1923    (1950): < 'echo 14' > is a NORMAL COMMAND
pp: 1941   pt: 1924   cp: 1941   ct: 1924   lbp: 1940  bp: 1940   BP: 1941  BS: 2   lBS: 2   PP: 1923    (1941): < 'echo 9.999' > is a NORMAL COMMAND
9.5
pp: 1941   pt: 1924   cp: 1941   ct: 1924   lbp: 1940  bp: 1940   BP: 1941  BS: 2   lBS: 2   PP: 1923    (1941): < 'echo 9.5' > is a NORMAL COMMAND
pp: 1924   pt: 1924   cp: 1952   ct: 1924   lbp: 1943  bp: 1949   BP: 1952  BS: 2   lBS: 1   PP: 1923    < pid: 1952 > is a BACKGROUND FORK
pp: 1924   pt: 1924   cp: 1953   ct: 1954   lbp: 1943  bp: 1952   BP: 1955  BS: 3   lBS: 1   PP: 1923    < pid: 1955 > is a BACKGROUND FORK
pp: 1952   pt: 1924   cp: 1952   ct: 1924   lbp: 1949  bp: 1956   BP: 1952  BS: 2   lBS: 2   PP: 1923    (1952): < 'echo a' > is a SIMPLE FORK *
b
a
pp: 1924   pt: 1924   cp: 1954   ct: 1954   lbp: 1943  bp: 1957   BP: 1954  BS: 2   lBS: 1   PP: 1923    < pid: 1954 > is a SUBSHELL
pp: 1953   pt: 1954   cp: 1953   ct: 1954   lbp: 1952  bp: 1952   BP: 1955  BS: 3   lBS: 3   PP: 1923    (1955): < 'echo b' > is a NORMAL COMMAND
A2
pp: 1924   pt: 1924   cp: 1954   ct: 1954   lbp: 1943  bp: 1953   BP: 1958  BS: 4   lBS: 1   PP: 1923    < pid: 1958 > is a SUBSHELL
pp: 1954   pt: 1954   cp: 1954   ct: 1954   lbp: 1957  bp: 1959   BP: 1954  BS: 2   lBS: 2   PP: 1923    (1954): < 'echo A2' > is a SIMPLE FORK
A1
pp: 1954   pt: 1954   cp: 1954   ct: 1954   lbp: 1959  bp: 1959   BP: 1954  BS: 2   lBS: 2   PP: 1923    (1954): < 'echo A1' > is a NORMAL COMMAND
A5
pp: 1954   pt: 1954   cp: 1954   ct: 1954   lbp: 1953  bp: 1960   BP: 1958  BS: 4   lBS: 4   PP: 1923    (1958): < 'echo A5' > is a SIMPLE FORK
pp: 1924   pt: 1924   cp: 1954   ct: 1924   lbp: 1943  bp: 1961   BP: 1957  BS: 3   lBS: 1   PP: 1923    < pid: 1957 > is a BACKGROUND FORK
A3
pp: 1924   pt: 1924   cp: 1954   ct: 1924   lbp: 1943  bp: 1953   BP: 1961  BS: 4   lBS: 1   PP: 1923    < pid: 1961 > is a BACKGROUND FORK
A4
pp: 1954   pt: 1924   cp: 1954   ct: 1924   lbp: 1961  bp: 1961   BP: 1957  BS: 3   lBS: 3   PP: 1923    (1957): < 'echo A3' > is a NORMAL COMMAND
pp: 1954   pt: 1924   cp: 1954   ct: 1924   lbp: 1953  bp: 1953   BP: 1961  BS: 4   lBS: 4   PP: 1923    (1961): < 'echo A4' > is a NORMAL COMMAND
pp: 1924   pt: 1924   cp: 1924   ct: 1924   lbp: 1943  bp: 1953   BP: 1928  BS: 1   lBS: 1   PP: 1923    (1928): < 'echo 12' > is a SIMPLE FORK

EOF


########################################################

(
set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=''
subshell_pid=''
next_is_simple_fork_flag=false
this_is_simple_fork_flag=false

trap 'wait' EXIT

trap 'is_bg=false
is_subshell=false
cmd_type='"''"'
if ${next_is_simple_fork_flag}; then
  next_is_simple_fork_flag=false
  this_is_simple_fork_flag=true
else
  this_is_simple_fork_flag=false
fi
if (( last_subshell == BASH_SUBSHELL )); then
  (( last_bg_pid == $! )) || is_bg=true;
else
  is_subshell=true
  subshell_pid=$BASHPID 
  trap '"'"'wait'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || is_bg=true
fi
if ${is_subshell} && ${is_bg}; then
  (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )) && next_is_simple_fork_flag=true
    cmd_type="BACKGROUND FORK"
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif ${is_bg}; then
  cmd_type="SIMPLE FORK"
else
  cmd_type="NORMAL COMMAND"
fi
if ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    < pid: %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "${PPID:-\?}" "$BASHPID" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
elif [[ $last_command ]]; then
  ${this_is_simple_fork_flag} && (( BASHPID < $! )) && cmd_type="SIMPLE FORK *"
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "${PPID:-\?}" "$BASHPID" "${last_command@Q}" "$cmd_type"
fi >&$fd
last_command="$BASH_COMMAND"
last_bg_pid=$!
unset cmd_type
' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1; 
echo 9.2 & } &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

( echo a & ) &
{ ( echo b ) & } &


( ( ( echo A5 & ); { echo A4; } & echo A3; ) & echo A2 & echo A1)

trap - DEBUG

) {fd}>&2

:<<'EOF'
0
pp: 5754   pt: 5754   cp: 5754   ct: 5754   lbp: 5759  bp: 5759   BP: 5758  BS: 1   lBS: 1   PP: 5753    (5758): < 'echo 0' > is a NORMAL COMMAND
1
pp: 5754   pt: 5754   cp: 5760   ct: 5760   lbp: 5759  bp: 5759   BP: 5760  BS: 2   lBS: 1   PP: 5753    < pid: 5760 > is a SUBSHELL
2
pp: 5760   pt: 5760   cp: 5760   ct: 5760   lbp: 5759  bp: 5759   BP: 5760  BS: 2   lBS: 2   PP: 5753    (5760): < 'echo 2' > is a NORMAL COMMAND
pp: 5754   pt: 5754   cp: 5754   ct: 5754   lbp: 5759  bp: 5759   BP: 5758  BS: 1   lBS: 1   PP: 5753    (5758): < 'echo 1' > is a NORMAL COMMAND
3
pp: 5754   pt: 5754   cp: 5754   ct: 5754   lbp: 5759  bp: 5761   BP: 5758  BS: 1   lBS: 1   PP: 5753    (5758): < 'echo 3' > is a SIMPLE FORK
4
pp: 5754   pt: 5754   cp: 5763   ct: 5764   lbp: 5761  bp: 5762   BP: 5763  BS: 2   lBS: 1   PP: 5753    < pid: 5763 > is a BACKGROUND FORK
5
pp: 5763   pt: 5764   cp: 5763   ct: 5764   lbp: 5762  bp: 5762   BP: 5763  BS: 2   lBS: 2   PP: 5753    (5763): < 'echo 5' > is a NORMAL COMMAND
pp: 5754   pt: 5754   cp: 5764   ct: 5764   lbp: 5761  bp: 5763   BP: 5764  BS: 2   lBS: 1   PP: 5753    < pid: 5764 > is a SUBSHELL
6
pp: 5764   pt: 5764   cp: 5764   ct: 5764   lbp: 5763  bp: 5765   BP: 5764  BS: 2   lBS: 2   PP: 5753    (5764): < 'echo 6' > is a SIMPLE FORK
pp: 5754   pt: 5754   cp: 5766   ct: 5767   lbp: 5761  bp: 5763   BP: 5766  BS: 2   lBS: 1   PP: 5753    < pid: 5766 > is a BACKGROUND FORK
7
pp: 5754   pt: 5754   cp: 5767   ct: 5767   lbp: 5761  bp: 5766   BP: 5767  BS: 2   lBS: 1   PP: 5753    < pid: 5767 > is a SUBSHELL
8
pp: 5766   pt: 5767   cp: 5766   ct: 5767   lbp: 5763  bp: 5763   BP: 5766  BS: 2   lBS: 2   PP: 5753    (5766): < 'echo 7' > is a NORMAL COMMAND
pp: 5767   pt: 5767   cp: 5767   ct: 5767   lbp: 5766  bp: 5766   BP: 5767  BS: 2   lBS: 2   PP: 5753    (5767): < 'echo 8' > is a NORMAL COMMAND
pp: 5754   pt: 5754   cp: 5768   ct: 5754   lbp: 5761  bp: 5766   BP: 5768  BS: 2   lBS: 1   PP: 5753    < pid: 5768 > is a BACKGROUND FORK
pp: 5754   pt: 5754   cp: 5769   ct: 5754   lbp: 5761  bp: 5768   BP: 5769  BS: 2   lBS: 1   PP: 5753    < pid: 5769 > is a BACKGROUND FORK
9.1
pp: 5754   pt: 5754   cp: 5754   ct: 5754   lbp: 5761  bp: 5771   BP: 5758  BS: 1   lBS: 1   PP: 5753    (5758): < 'echo 4' > is a SIMPLE FORK
pp: 5769   pt: 5754   cp: 5769   ct: 5754   lbp: 5768  bp: 5768   BP: 5769  BS: 2   lBS: 2   PP: 5753    (5769): < 'echo 9.1' > is a NORMAL COMMAND
11
pp: 5754   pt: 5754   cp: 5770   ct: 5754   lbp: 5761  bp: 5769   BP: 5770  BS: 2   lBS: 1   PP: 5753    < pid: 5770 > is a BACKGROUND FORK
9.999
pp: 5768   pt: 5754   cp: 5768   ct: 5754   lbp: 5766  bp: 5772   BP: 5768  BS: 2   lBS: 2   PP: 5753    (5768): < 'echo 9' > is a SIMPLE FORK *
pp: 5754   pt: 5754   cp: 5754   ct: 5754   lbp: 5771  bp: 5771   BP: 5758  BS: 1   lBS: 1   PP: 5753    (5758): < 'echo 11' > is a NORMAL COMMAND
9
pp: 5769   pt: 5754   cp: 5769   ct: 5754   lbp: 5768  bp: 5773   BP: 5769  BS: 2   lBS: 2   PP: 5753    (5769): < 'echo 9.2' > is a SIMPLE FORK
12
pp: 5754   pt: 5754   cp: 5771   ct: 5754   lbp: 5761  bp: 5770   BP: 5771  BS: 2   lBS: 1   PP: 5753    < pid: 5771 > is a BACKGROUND FORK
pp: 5770   pt: 5754   cp: 5770   ct: 5777   lbp: 5769  bp: 5769   BP: 5774  BS: 3   lBS: 2   PP: 5753    < pid: 5774 > is a BACKGROUND FORK
pp: 5771   pt: 5754   cp: 5771   ct: 5754   lbp: 5770  bp: 5778   BP: 5771  BS: 2   lBS: 2   PP: 5753    (5771): < 'echo 10' > is a SIMPLE FORK *
pp: 5754   pt: 5754   cp: 5776   ct: 5777   lbp: 5771  bp: 5775   BP: 5776  BS: 2   lBS: 1   PP: 5753    < pid: 5776 > is a BACKGROUND FORK
pp: 5754   pt: 5754   cp: 5777   ct: 5777   lbp: 5771  bp: 5776   BP: 5777  BS: 2   lBS: 1   PP: 5753    < pid: 5777 > is a SUBSHELL
13
14
pp: 5777   pt: 5777   cp: 5777   ct: 5777   lbp: 5776  bp: 5776   BP: 5777  BS: 2   lBS: 2   PP: 5753    (5777): < 'echo 14' > is a NORMAL COMMAND
pp: 5776   pt: 5777   cp: 5776   ct: 5777   lbp: 5775  bp: 5775   BP: 5776  BS: 2   lBS: 2   PP: 5753    (5776): < 'echo 13' > is a NORMAL COMMAND
pp: 5770   pt: 5777   cp: 5770   ct: 5777   lbp: 5769  bp: 5779   BP: 5774  BS: 3   lBS: 3   PP: 5753    (5774): < 'echo 9.3' > is a SIMPLE FORK
9.4
pp: 5770   pt: 5777   cp: 5770   ct: 5777   lbp: 5779  bp: 5779   BP: 5774  BS: 3   lBS: 3   PP: 5753    (5774): < 'echo 9.4' > is a NORMAL COMMAND
9.3
10
pp: 5754   pt: 5754   cp: 5780   ct: 5754   lbp: 5771  bp: 5776   BP: 5780  BS: 2   lBS: 1   PP: 5753    < pid: 5780 > is a BACKGROUND FORK
9.2
a
pp: 5754   pt: 5754   cp: 5782   ct: 5782   lbp: 5771  bp: 5785   BP: 5782  BS: 2   lBS: 1   PP: 5753    < pid: 5782 > is a SUBSHELL
pp: 5754   pt: 5754   cp: 5781   ct: 5782   lbp: 5771  bp: 5780   BP: 5783  BS: 3   lBS: 1   PP: 5753    < pid: 5783 > is a BACKGROUND FORK
b
pp: 5781   pt: 5782   cp: 5781   ct: 5782   lbp: 5780  bp: 5780   BP: 5783  BS: 3   lBS: 3   PP: 5753    (5783): < 'echo b' > is a NORMAL COMMAND
pp: 5782   pt: 5782   cp: 5782   ct: 5782   lbp: 5785  bp: 5787   BP: 5782  BS: 2   lBS: 2   PP: 5753    (5782): < 'echo A2' > is a SIMPLE FORK
A2
A1
pp: 5780   pt: 5754   cp: 5780   ct: 5754   lbp: 5776  bp: 5784   BP: 5780  BS: 2   lBS: 2   PP: 5753    (5780): < 'echo a' > is a SIMPLE FORK *
pp: 5754   pt: 5754   cp: 5782   ct: 5754   lbp: 5771  bp: 5781   BP: 5786  BS: 4   lBS: 1   PP: 5753    < pid: 5786 > is a BACKGROUND FORK
pp: 5782   pt: 5782   cp: 5782   ct: 5782   lbp: 5787  bp: 5787   BP: 5782  BS: 2   lBS: 2   PP: 5753    (5782): < 'echo A1' > is a NORMAL COMMAND
A5
pp: 5770   pt: 5754   cp: 5770   ct: 5754   lbp: 5769  bp: 5769   BP: 5770  BS: 2   lBS: 2   PP: 5753    (5770): < 'echo 9.999' > is a NORMAL COMMAND
9.5
pp: 5782   pt: 5754   cp: 5782   ct: 5754   lbp: 5781  bp: 5788   BP: 5786  BS: 4   lBS: 4   PP: 5753    (5786): < 'echo A5' > is a SIMPLE FORK
pp: 5770   pt: 5754   cp: 5770   ct: 5754   lbp: 5769  bp: 5769   BP: 5770  BS: 2   lBS: 2   PP: 5753    (5770): < 'echo 9.5' > is a NORMAL COMMAND
pp: 5754   pt: 5754   cp: 5782   ct: 5782   lbp: 5771  bp: 5789   BP: 5785  BS: 3   lBS: 1   PP: 5753    < pid: 5785 > is a SUBSHELL
A3
pp: 5754   pt: 5754   cp: 5782   ct: 5782   lbp: 5771  bp: 5781   BP: 5789  BS: 4   lBS: 1   PP: 5753    < pid: 5789 > is a SUBSHELL
A4
pp: 5782   pt: 5782   cp: 5782   ct: 5782   lbp: 5789  bp: 5789   BP: 5785  BS: 3   lBS: 3   PP: 5753    (5785): < 'echo A3' > is a NORMAL COMMAND
pp: 5782   pt: 5782   cp: 5782   ct: 5782   lbp: 5781  bp: 5781   BP: 5789  BS: 4   lBS: 4   PP: 5753    (5789): < 'echo A4' > is a NORMAL COMMAND
pp: 5754   pt: 5754   cp: 5754   ct: 5754   lbp: 5771  bp: 5781   BP: 5758  BS: 1   lBS: 1   PP: 5753    (5758): < 'echo 12' > is a SIMPLE FORK
EOF









######################################################################
(



set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=''
subshell_pid=''

trap ':' EXIT

trap 'is_bg=false
is_subshell=false
if (( last_subshell == BASH_SUBSHELL )); then
  (( last_bg_pid == $! )) || is_bg=true;
else
  is_subshell=true
  subshell_pid=$BASHPID 
  trap '"'"':'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) || is_bg=true
fi
last_bg_pid=$!
if ${is_subshell} && ${is_bg}; then
  if (( child_pgid == BASHPID )) && (( child_tpid == parent_pgid )) && (( child_tpid == parent_tpid )); then
    cmd_type="FORK and/or SUBSHELL"
    
  else
    cmd_type="BACKGROUND FORK"
  fi
elif ${is_subshell}; then
  cmd_type="SUBSHELL"
elif ${is_bg}; then
  if (( parent_pgid != parent_tpid )); then
    cmd_type="NORMAL COMMAND"
  else
    cmd_type="SIMPLE FORK"
  fi
else
  cmd_type="NORMAL COMMAND"
fi >&$fd
if ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "${PPID:-\?}" "$BASHPID" "${BASH_COMMAND@Q}" "$cmd_type"
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
  last_subshell="$BASH_SUBSHELL"
else
    [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is a %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "${PPID:-\?}" "$BASHPID" "${last_command@Q}" "$cmd_type"
fi
last_command="$BASH_COMMAND"
unset cmd_type
' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 9.1 & echo 9.2; } &
{ echo 9.999; ( echo 9.3 & echo 9.4 ); echo 9.5; } &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )

( echo a & ) &
{ ( echo b ) & } &


( ( ( echo 5 & ); { echo 4; } & echo 3; ) & echo 2 & echo 1 )

wait

) {fd}>&2



:<<'EOF'
0
pp: 6686   pt: 6686   cp: 6686   ct: 6686   lbp: 6691  bp: 6691   BP: 6690  BS: 1   lBS: 1   PP: 6685    (6690): < 'echo 0' > is a NORMAL COMMAND
1
pp: 6686   pt: 6686   cp: 6692   ct: 6692   lbp: 6691  bp: 6691   BP: 6692  BS: 2   lBS: 1   PP: 6685    (6692): < 'echo 2' > is a SUBSHELL
2
pp: 6692   pt: 6692   cp: 6692   ct: 6692   lbp: 6691  bp: 6691   BP: 6692  BS: 2   lBS: 2   PP: 6685    (6692): < 'echo 2' > is a NORMAL COMMAND
pp: 6686   pt: 6686   cp: 6686   ct: 6686   lbp: 6691  bp: 6691   BP: 6690  BS: 1   lBS: 1   PP: 6685    (6690): < 'echo 1' > is a NORMAL COMMAND
3
pp: 6686   pt: 6686   cp: 6686   ct: 6686   lbp: 6693  bp: 6693   BP: 6690  BS: 1   lBS: 1   PP: 6685    (6690): < 'echo 3' > is a SIMPLE FORK
4
pp: 6686   pt: 6686   cp: 6695   ct: 6696   lbp: 6694  bp: 6694   BP: 6695  BS: 2   lBS: 1   PP: 6685    (6695): < 'echo 5' > is a BACKGROUND FORK
5
pp: 6686   pt: 6686   cp: 6696   ct: 6696   lbp: 6695  bp: 6695   BP: 6696  BS: 2   lBS: 1   PP: 6685    (6696): < 'echo 6' > is a SUBSHELL
pp: 6695   pt: 6696   cp: 6695   ct: 6696   lbp: 6694  bp: 6694   BP: 6695  BS: 2   lBS: 2   PP: 6685    (6695): < 'echo 5' > is a NORMAL COMMAND
6
pp: 6696   pt: 6696   cp: 6696   ct: 6696   lbp: 6697  bp: 6697   BP: 6696  BS: 2   lBS: 2   PP: 6685    (6696): < 'echo 6' > is a SIMPLE FORK
pp: 6686   pt: 6686   cp: 6698   ct: 6699   lbp: 6695  bp: 6695   BP: 6698  BS: 2   lBS: 1   PP: 6685    (6698): < 'echo 7' > is a BACKGROUND FORK
7
pp: 6686   pt: 6686   cp: 6699   ct: 6699   lbp: 6698  bp: 6698   BP: 6699  BS: 2   lBS: 1   PP: 6685    (6699): < 'echo 8' > is a SUBSHELL
8
pp: 6698   pt: 6699   cp: 6698   ct: 6699   lbp: 6695  bp: 6695   BP: 6698  BS: 2   lBS: 2   PP: 6685    (6698): < 'echo 7' > is a NORMAL COMMAND
pp: 6699   pt: 6699   cp: 6699   ct: 6699   lbp: 6698  bp: 6698   BP: 6699  BS: 2   lBS: 2   PP: 6685    (6699): < 'echo 8' > is a NORMAL COMMAND
pp: 6686   pt: 6686   cp: 6700   ct: 6686   lbp: 6698  bp: 6698   BP: 6700  BS: 2   lBS: 1   PP: 6685    (6700): < 'echo 9' > is a FORK and/or SUBSHELL
pp: 6686   pt: 6686   cp: 6701   ct: 6686   lbp: 6700  bp: 6700   BP: 6701  BS: 2   lBS: 1   PP: 6685    (6701): < 'echo 9.1' > is a FORK and/or SUBSHELL
pp: 6686   pt: 6686   cp: 6686   ct: 6686   lbp: 6703  bp: 6703   BP: 6690  BS: 1   lBS: 1   PP: 6685    (6690): < 'echo 4' > is a SIMPLE FORK
11
9
pp: 6686   pt: 6686   cp: 6702   ct: 6686   lbp: 6701  bp: 6701   BP: 6702  BS: 2   lBS: 1   PP: 6685    (6702): < 'echo 9.999' > is a FORK and/or SUBSHELL
9.999
pp: 6686   pt: 6686   cp: 6703   ct: 6686   lbp: 6702  bp: 6702   BP: 6703  BS: 2   lBS: 1   PP: 6685    (6703): < 'echo 10' > is a FORK and/or SUBSHELL
pp: 6700   pt: 6686   cp: 6700   ct: 6686   lbp: 6704  bp: 6704   BP: 6700  BS: 2   lBS: 2   PP: 6685    (6700): < 'echo 9' > is a NORMAL COMMAND
pp: 6686   pt: 6686   cp: 6686   ct: 6686   lbp: 6703  bp: 6703   BP: 6690  BS: 1   lBS: 1   PP: 6685    (6690): < 'echo 11' > is a NORMAL COMMAND
9.1
pp: 6701   pt: 6686   cp: 6701   ct: 6686   lbp: 6705  bp: 6705   BP: 6701  BS: 2   lBS: 2   PP: 6685    (6701): < 'echo 9.1' > is a NORMAL COMMAND
9.2
10
12
pp: 6703   pt: 6686   cp: 6703   ct: 6686   lbp: 6707  bp: 6707   BP: 6703  BS: 2   lBS: 2   PP: 6685    (6703): < 'echo 10' > is a NORMAL COMMAND
pp: 6701   pt: 6686   cp: 6701   ct: 6686   lbp: 6705  bp: 6705   BP: 6701  BS: 2   lBS: 2   PP: 6685    (6701): < 'echo 9.2' > is a NORMAL COMMAND
pp: 6702   pt: 6686   cp: 6702   ct: 6686   lbp: 6701  bp: 6701   BP: 6706  BS: 3   lBS: 2   PP: 6685    (6706): < 'echo 9.3' > is a BACKGROUND FORK
9.3
pp: 6686   pt: 6686   cp: 6709   ct: 6702   lbp: 6708  bp: 6708   BP: 6709  BS: 2   lBS: 1   PP: 6685    (6709): < 'echo 13' > is a BACKGROUND FORK
13
pp: 6686   pt: 6686   cp: 6710   ct: 6702   lbp: 6709  bp: 6709   BP: 6710  BS: 2   lBS: 1   PP: 6685    (6710): < 'echo 14' > is a BACKGROUND FORK
pp: 6702   pt: 6686   cp: 6702   ct: 6686   lbp: 6711  bp: 6711   BP: 6706  BS: 3   lBS: 3   PP: 6685    (6706): < 'echo 9.3' > is a NORMAL COMMAND
14
pp: 6709   pt: 6702   cp: 6709   ct: 6702   lbp: 6708  bp: 6708   BP: 6709  BS: 2   lBS: 2   PP: 6685    (6709): < 'echo 13' > is a NORMAL COMMAND
9.4
pp: 6702   pt: 6686   cp: 6702   ct: 6686   lbp: 6711  bp: 6711   BP: 6706  BS: 3   lBS: 3   PP: 6685    (6706): < 'echo 9.4' > is a NORMAL COMMAND
pp: 6710   pt: 6702   cp: 6710   ct: 6702   lbp: 6709  bp: 6709   BP: 6710  BS: 2   lBS: 2   PP: 6685    (6710): < 'echo 14' > is a NORMAL COMMAND
pp: 6702   pt: 6686   cp: 6702   ct: 6686   lbp: 6701  bp: 6701   BP: 6702  BS: 2   lBS: 2   PP: 6685    (6702): < 'echo 9.999' > is a NORMAL COMMAND
9.5
pp: 6702   pt: 6686   cp: 6702   ct: 6686   lbp: 6701  bp: 6701   BP: 6702  BS: 2   lBS: 2   PP: 6685    (6702): < 'echo 9.5' > is a NORMAL COMMAND
pp: 6686   pt: 6686   cp: 6712   ct: 6714   lbp: 6709  bp: 6709   BP: 6712  BS: 2   lBS: 1   PP: 6685    (6712): < 'echo a' > is a BACKGROUND FORK
a
pp: 6686   pt: 6686   cp: 6713   ct: 6714   lbp: 6712  bp: 6712   BP: 6715  BS: 3   lBS: 1   PP: 6685    (6715): < 'echo b' > is a BACKGROUND FORK
pp: 6686   pt: 6686   cp: 6714   ct: 6714   lbp: 6716  bp: 6716   BP: 6714  BS: 2   lBS: 1   PP: 6685    (6714): < 'echo 2' > is a SUBSHELL
pp: 6712   pt: 6714   cp: 6712   ct: 6714   lbp: 6717  bp: 6717   BP: 6712  BS: 2   lBS: 2   PP: 6685    (6712): < 'echo a' > is a NORMAL COMMAND
b
pp: 6713   pt: 6714   cp: 6713   ct: 6714   lbp: 6712  bp: 6712   BP: 6715  BS: 3   lBS: 3   PP: 6685    (6715): < 'echo b' > is a NORMAL COMMAND
pp: 6686   pt: 6686   cp: 6714   ct: 6714   lbp: 6713  bp: 6713   BP: 6718  BS: 4   lBS: 1   PP: 6685    (6718): < 'echo 5' > is a SUBSHELL
2
pp: 6714   pt: 6714   cp: 6714   ct: 6714   lbp: 6719  bp: 6719   BP: 6714  BS: 2   lBS: 2   PP: 6685    (6714): < 'echo 2' > is a SIMPLE FORK
1
5
pp: 6714   pt: 6714   cp: 6714   ct: 6714   lbp: 6720  bp: 6720   BP: 6718  BS: 4   lBS: 4   PP: 6685    (6718): < 'echo 5' > is a SIMPLE FORK
pp: 6714   pt: 6714   cp: 6714   ct: 6714   lbp: 6719  bp: 6719   BP: 6714  BS: 2   lBS: 2   PP: 6685    (6714): < 'echo 1' > is a NORMAL COMMAND
pp: 6686   pt: 6686   cp: 6686   ct: 6686   lbp: 6713  bp: 6713   BP: 6690  BS: 1   lBS: 1   PP: 6685    (6690): < 'echo 12' > is a SIMPLE FORK
pp: 6686   pt: 6686   cp: 6714   ct: 6686   lbp: 6713  bp: 6713   BP: 6721  BS: 4   lBS: 1   PP: 6685    (6721): < 'echo 4' > is a BACKGROUND FORK
pp: 6686   pt: 6686   cp: 6686   ct: 6686   lbp: 6713  bp: 6713   BP: 6690  BS: 1   lBS: 1   PP: 6685    (6690): < 'wait' > is a NORMAL COMMAND
pp: 6686   pt: 6686   cp: 6714   ct: 6686   lbp: 6721  bp: 6721   BP: 6716  BS: 3   lBS: 1   PP: 6685    (6716): < 'echo 3' > is a BACKGROUND FORK
4
3
pp: 6714   pt: 6686   cp: 6714   ct: 6686   lbp: 6713  bp: 6713   BP: 6721  BS: 4   lBS: 4   PP: 6685    (6721): < 'echo 4' > is a NORMAL COMMAND
pp: 6714   pt: 6686   cp: 6714   ct: 6686   lbp: 6721  bp: 6721   BP: 6716  BS: 3   lBS: 3   PP: 6685    (6716): < 'echo 3' > is a NORMAL COMMAND

EOF

###########################################################

(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=''
subshell_pid=''

trap ':' EXIT

trap 'is_bg=false
is_subshell=false
if (( last_subshell == BASH_SUBSHELL )); then
  (( last_bg_pid == $! )) || is_bg=true;
else
  is_subshell=true
  subshell_pid=$BASHPID 
  trap '"'"':'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) ||  is_bg=true
fi
last_bg_pid=$!
if ${is_subshell} && ${is_bg}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "pid: $BASHPID" "BACKGROUND FORK"
elif ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "pid: $BASHPID" "SUBSHELL"
elif ${is_bg}; then
  if (( parent_pgid != parent_tpid )); then
    [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "$last_command" "NORMAL COMMAND"
  else
    [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "$last_command" "SIMPLE FORK"
  fi
else
  [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "$last_command" "NORMAL COMMAND"
fi >&$fd
last_command="$BASH_COMMAND"
${is_subshell} && {
  last_subshell=$BASH_SUBSHELL
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
}' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 10 & } &

echo 11
echo 12 &
( echo 13 ) &
( echo 14 )


( ( ( echo 5 & ); { echo 4; } & echo 3; ) & echo 2 & echo 1 )

wait

) {fd}>&2


:<<'EOF'
0
pp: 549   pt: 549   cp: 549   ct: 549   lbp: 554  bp: 554   BP: 553  BS: 1   lBS: 1   PP: 548    (553): < echo 0 > is NORMAL COMMAND
1
pp: 549   pt: 549   cp: 555   ct: 555   lbp: 554  bp: 554   BP: 555  BS: 2   lBS: 1   PP: 548    (555): < pid: 555 > is SUBSHELL
2
pp: 555   pt: 555   cp: 555   ct: 555   lbp: 554  bp: 554   BP: 555  BS: 2   lBS: 2   PP: 548    (555): < echo 2 > is NORMAL COMMAND
pp: 549   pt: 549   cp: 549   ct: 549   lbp: 554  bp: 554   BP: 553  BS: 1   lBS: 1   PP: 548    (553): < echo 1 > is NORMAL COMMAND
3
pp: 549   pt: 549   cp: 549   ct: 549   lbp: 556  bp: 556   BP: 553  BS: 1   lBS: 1   PP: 548    (553): < echo 3 > is SIMPLE FORK
4
pp: 549   pt: 549   cp: 558   ct: 559   lbp: 557  bp: 557   BP: 558  BS: 2   lBS: 1   PP: 548    (558): < pid: 558 > is BACKGROUND FORK
5
pp: 549   pt: 549   cp: 559   ct: 559   lbp: 558  bp: 558   BP: 559  BS: 2   lBS: 1   PP: 548    (559): < pid: 559 > is SUBSHELL
pp: 558   pt: 559   cp: 558   ct: 559   lbp: 557  bp: 557   BP: 558  BS: 2   lBS: 2   PP: 548    (558): < echo 5 > is NORMAL COMMAND
6
pp: 559   pt: 559   cp: 559   ct: 559   lbp: 560  bp: 560   BP: 559  BS: 2   lBS: 2   PP: 548    (559): < echo 6 > is SIMPLE FORK
pp: 549   pt: 549   cp: 561   ct: 562   lbp: 558  bp: 558   BP: 561  BS: 2   lBS: 1   PP: 548    (561): < pid: 561 > is BACKGROUND FORK
7
pp: 549   pt: 549   cp: 562   ct: 562   lbp: 561  bp: 561   BP: 562  BS: 2   lBS: 1   PP: 548    (562): < pid: 562 > is SUBSHELL
8
pp: 561   pt: 562   cp: 561   ct: 562   lbp: 558  bp: 558   BP: 561  BS: 2   lBS: 2   PP: 548    (561): < echo 7 > is NORMAL COMMAND
pp: 562   pt: 562   cp: 562   ct: 562   lbp: 561  bp: 561   BP: 562  BS: 2   lBS: 2   PP: 548    (562): < echo 8 > is NORMAL COMMAND
pp: 549   pt: 549   cp: 549   ct: 549   lbp: 564  bp: 564   BP: 553  BS: 1   lBS: 1   PP: 548    (553): < echo 4 > is SIMPLE FORK
11
pp: 549   pt: 549   cp: 563   ct: 549   lbp: 561  bp: 561   BP: 563  BS: 2   lBS: 1   PP: 548    (563): < pid: 563 > is BACKGROUND FORK
pp: 549   pt: 549   cp: 564   ct: 549   lbp: 563  bp: 563   BP: 564  BS: 2   lBS: 1   PP: 548    (564): < pid: 564 > is BACKGROUND FORK
pp: 549   pt: 549   cp: 549   ct: 549   lbp: 564  bp: 564   BP: 553  BS: 1   lBS: 1   PP: 548    (553): < echo 11 > is NORMAL COMMAND
9
10
pp: 563   pt: 549   cp: 563   ct: 549   lbp: 565  bp: 565   BP: 563  BS: 2   lBS: 2   PP: 548    (563): < echo 9 > is NORMAL COMMAND
12
pp: 564   pt: 549   cp: 564   ct: 549   lbp: 567  bp: 567   BP: 564  BS: 2   lBS: 2   PP: 548    (564): < echo 10 > is NORMAL COMMAND
pp: 549   pt: 549   cp: 568   ct: 569   lbp: 566  bp: 566   BP: 568  BS: 2   lBS: 1   PP: 548    (568): < pid: 568 > is BACKGROUND FORK
13
pp: 549   pt: 549   cp: 569   ct: 569   lbp: 568  bp: 568   BP: 569  BS: 2   lBS: 1   PP: 548    (569): < pid: 569 > is SUBSHELL
pp: 568   pt: 569   cp: 568   ct: 569   lbp: 566  bp: 566   BP: 568  BS: 2   lBS: 2   PP: 548    (568): < echo 13 > is NORMAL COMMAND
14
pp: 569   pt: 569   cp: 569   ct: 569   lbp: 568  bp: 568   BP: 569  BS: 2   lBS: 2   PP: 548    (569): < echo 14 > is NORMAL COMMAND
pp: 549   pt: 549   cp: 570   ct: 570   lbp: 571  bp: 571   BP: 570  BS: 2   lBS: 1   PP: 548    (570): < pid: 570 > is SUBSHELL
2
pp: 570   pt: 570   cp: 570   ct: 570   lbp: 573  bp: 573   BP: 570  BS: 2   lBS: 2   PP: 548    (570): < echo 2 > is SIMPLE FORK
pp: 549   pt: 549   cp: 570   ct: 570   lbp: 568  bp: 568   BP: 572  BS: 4   lBS: 1   PP: 548    (572): < pid: 572 > is SUBSHELL
1
pp: 570   pt: 570   cp: 570   ct: 570   lbp: 573  bp: 573   BP: 570  BS: 2   lBS: 2   PP: 548    (570): < echo 1 > is NORMAL COMMAND
5
pp: 570   pt: 570   cp: 570   ct: 570   lbp: 574  bp: 574   BP: 572  BS: 4   lBS: 4   PP: 548    (572): < echo 5 > is SIMPLE FORK
pp: 549   pt: 549   cp: 549   ct: 549   lbp: 568  bp: 568   BP: 553  BS: 1   lBS: 1   PP: 548    (553): < echo 12 > is SIMPLE FORK
pp: 549   pt: 549   cp: 549   ct: 549   lbp: 568  bp: 568   BP: 553  BS: 1   lBS: 1   PP: 548    (553): < wait > is NORMAL COMMAND
pp: 549   pt: 549   cp: 570   ct: 549   lbp: 575  bp: 575   BP: 571  BS: 3   lBS: 1   PP: 548    (571): < pid: 571 > is BACKGROUND FORK
3
pp: 549   pt: 549   cp: 570   ct: 549   lbp: 568  bp: 568   BP: 575  BS: 4   lBS: 1   PP: 548    (575): < pid: 575 > is BACKGROUND FORK
pp: 570   pt: 549   cp: 570   ct: 549   lbp: 575  bp: 575   BP: 571  BS: 3   lBS: 3   PP: 548    (571): < echo 3 > is NORMAL COMMAND
4
pp: 570   pt: 549   cp: 570   ct: 549   lbp: 568  bp: 568   BP: 575  BS: 4   lBS: 4   PP: 548    (575): < echo 4 > is NORMAL COMMAND

EOF










################################################################################


#                             Online Bash Shell.
#                 Code, Compile, Run and Debug Bash script online.
# Write your code in this editor and press "Run" button to execute it.

(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=''
subshell_pid=''

trap ':' EXIT

trap 'is_bg=false
is_subshell=false
if (( last_subshell == BASH_SUBSHELL )); then
  (( last_bg_pid == $! )) || is_bg=true;
else
  is_subshell=true
  subshell_pid=$BASHPID 
  trap '"'"':'"'"' EXIT 
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) ||  is_bg=true
fi
last_bg_pid=$!
if ${is_subshell} && ${is_bg}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "pid: $BASHPID" "BACKGROUND FORK"
elif ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "pid: $BASHPID" "SUBSHELL"
elif ${is_bg}; then
  if   (( parent_pgid != parent_tpid )); then
    [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "$last_command" "NORMAL COMMAND"
  else
    [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "$last_command" "SIMPLE FORK"
  fi
else
  [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "$last_command" "NORMAL COMMAND"
fi >&$fd
last_command="$BASH_COMMAND"
${is_subshell} && {
  last_subshell=$BASH_SUBSHELL
  parent_pgid=$child_pgid
  parent_tpid=$child_tpid
}' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 10 & } &

wait

) {fd}>&2

:<<'EOF'
0
pp: 892   pt: 892   cp: 892   ct: 892   lbp: 897  bp: 897   BP: 896  BS: 1   lBS: 1   PP: 891    (896): < echo 0 > is NORMAL COMMAND
1
pp: 892   pt: 892   cp: 898   ct: 898   lbp: 897  bp: 897   BP: 898  BS: 2   lBS: 1   PP: 891    (898): < pid: 898 > is SUBSHELL
2
pp: 898   pt: 898   cp: 898   ct: 898   lbp: 897  bp: 897   BP: 898  BS: 2   lBS: 2   PP: 891    (898): < echo 2 > is NORMAL COMMAND
pp: 892   pt: 892   cp: 892   ct: 892   lbp: 897  bp: 897   BP: 896  BS: 1   lBS: 1   PP: 891    (896): < echo 1 > is NORMAL COMMAND
3
pp: 892   pt: 892   cp: 892   ct: 892   lbp: 899  bp: 899   BP: 896  BS: 1   lBS: 1   PP: 891    (896): < echo 3 > is SIMPLE FORK
4
pp: 892   pt: 892   cp: 901   ct: 902   lbp: 900  bp: 900   BP: 901  BS: 2   lBS: 1   PP: 891    (901): < pid: 901 > is BACKGROUND FORK
5
pp: 901   pt: 902   cp: 901   ct: 902   lbp: 900  bp: 900   BP: 901  BS: 2   lBS: 2   PP: 891    (901): < echo 5 > is NORMAL COMMAND
pp: 892   pt: 892   cp: 902   ct: 902   lbp: 901  bp: 901   BP: 902  BS: 2   lBS: 1   PP: 891    (902): < pid: 902 > is SUBSHELL
6
pp: 902   pt: 902   cp: 902   ct: 902   lbp: 903  bp: 903   BP: 902  BS: 2   lBS: 2   PP: 891    (902): < echo 6 > is SIMPLE FORK
pp: 892   pt: 892   cp: 904   ct: 905   lbp: 901  bp: 901   BP: 904  BS: 2   lBS: 1   PP: 891    (904): < pid: 904 > is BACKGROUND FORK
7
pp: 904   pt: 905   cp: 904   ct: 905   lbp: 901  bp: 901   BP: 904  BS: 2   lBS: 2   PP: 891    (904): < echo 7 > is NORMAL COMMAND
pp: 892   pt: 892   cp: 905   ct: 905   lbp: 904  bp: 904   BP: 905  BS: 2   lBS: 1   PP: 891    (905): < pid: 905 > is SUBSHELL
8
pp: 905   pt: 905   cp: 905   ct: 905   lbp: 904  bp: 904   BP: 905  BS: 2   lBS: 2   PP: 891    (905): < echo 8 > is NORMAL COMMAND
pp: 892   pt: 892   cp: 892   ct: 892   lbp: 907  bp: 907   BP: 896  BS: 1   lBS: 1   PP: 891    (896): < echo 4 > is SIMPLE FORK
pp: 892   pt: 892   cp: 906   ct: 892   lbp: 904  bp: 904   BP: 906  BS: 2   lBS: 1   PP: 891    (906): < pid: 906 > is BACKGROUND FORK
pp: 892   pt: 892   cp: 907   ct: 892   lbp: 906  bp: 906   BP: 907  BS: 2   lBS: 1   PP: 891    (907): < pid: 907 > is BACKGROUND FORK
9
10
pp: 906   pt: 892   cp: 906   ct: 892   lbp: 908  bp: 908   BP: 906  BS: 2   lBS: 2   PP: 891    (906): < echo 9 > is NORMAL COMMAND
pp: 907   pt: 892   cp: 907   ct: 892   lbp: 909  bp: 909   BP: 907  BS: 2   lBS: 2   PP: 891    (907): < echo 10 > is NORMAL COMMAND
pp: 892   pt: 892   cp: 892   ct: 892   lbp: 907  bp: 907   BP: 896  BS: 1   lBS: 1   PP: 891    (896): < wait > is NORMAL COMMAND
EOF






##################################################################

(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=''
subshell_pid=''

trap ':' EXIT

trap 'is_bg=false; is_subshell=false;
(( last_subshell == BASH_SUBSHELL )) || { is_subshell=true; subshell_pid=$BASHPID; trap '"'"':'"'"' EXIT; }
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
if ${is_subshell} || (( subshell_pid == BASHPID )); then
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) ||  is_bg=true
fi
${is_subshell} || (( last_bg_pid == $! )) || is_bg=true; last_bg_pid=$!
if ${is_subshell} && ${is_bg}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "pid: $BASHPID" "BACKGROUND FORK"
elif ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "pid: $BASHPID" "SUBSHELL"
elif ${is_bg}; then
  if   (( parent_pgid != parent_tpid )); then
    [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "$last_command" "NORMAL COMMAND"
  else
    [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "$last_command" "SIMPLE FORK"
  fi
else
  [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "$last_command" "NORMAL COMMAND"
fi >&$fd
last_command="$BASH_COMMAND"
${is_subshell} && last_subshell=$BASH_SUBSHELL
{ ${is_bg} || ${is_subshell}; } && {
 parent_pgid=$child_pgid
 parent_tpid=$child_tpid
 }' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
{ echo 10 & } &

:
wait

) {fd}>&2


# output

:<<'EOF'

0
pp: 12982   pt: 12982   cp: 12982   ct: 12982   lbp: 12987  bp: 12987   BP: 12986  BS: 1   lBS: 1   PP: 12981    (12986): < echo 0 > is NORMAL COMMAND
1
pp: 12982   pt: 12982   cp: 12988   ct: 12988   lbp: 12987  bp: 12987   BP: 12988  BS: 2   lBS: 1   PP: 12981    (12988): < pid: 12988 > is SUBSHELL
2
pp: 12988   pt: 12988   cp: 12988   ct: 12988   lbp: 12987  bp: 12987   BP: 12988  BS: 2   lBS: 2   PP: 12981    (12988): < echo 2 > is NORMAL COMMAND
pp: 12982   pt: 12982   cp: 12982   ct: 12982   lbp: 12987  bp: 12987   BP: 12986  BS: 1   lBS: 1   PP: 12981    (12986): < echo 1 > is NORMAL COMMAND
3
pp: 12982   pt: 12982   cp: 12982   ct: 12982   lbp: 12989  bp: 12989   BP: 12986  BS: 1   lBS: 1   PP: 12981    (12986): < echo 3 > is SIMPLE FORK
4
pp: 12982   pt: 12982   cp: 12991   ct: 12992   lbp: 12990  bp: 12990   BP: 12991  BS: 2   lBS: 1   PP: 12981    (12991): < pid: 12991 > is BACKGROUND FORK
5
pp: 12982   pt: 12982   cp: 12992   ct: 12992   lbp: 12991  bp: 12991   BP: 12992  BS: 2   lBS: 1   PP: 12981    (12992): < pid: 12992 > is SUBSHELL
pp: 12991   pt: 12992   cp: 12991   ct: 12992   lbp: 12990  bp: 12990   BP: 12991  BS: 2   lBS: 2   PP: 12981    (12991): < echo 5 > is NORMAL COMMAND
6
pp: 12992   pt: 12992   cp: 12992   ct: 12992   lbp: 12993  bp: 12993   BP: 12992  BS: 2   lBS: 2   PP: 12981    (12992): < echo 6 > is SIMPLE FORK
pp: 12982   pt: 12982   cp: 12994   ct: 12995   lbp: 12991  bp: 12991   BP: 12994  BS: 2   lBS: 1   PP: 12981    (12994): < pid: 12994 > is BACKGROUND FORK
7
pp: 12994   pt: 12995   cp: 12994   ct: 12995   lbp: 12991  bp: 12991   BP: 12994  BS: 2   lBS: 2   PP: 12981    (12994): < echo 7 > is NORMAL COMMAND
pp: 12982   pt: 12982   cp: 12995   ct: 12995   lbp: 12994  bp: 12994   BP: 12995  BS: 2   lBS: 1   PP: 12981    (12995): < pid: 12995 > is SUBSHELL
8
pp: 12995   pt: 12995   cp: 12995   ct: 12995   lbp: 12994  bp: 12994   BP: 12995  BS: 2   lBS: 2   PP: 12981    (12995): < echo 8 > is NORMAL COMMAND
pp: 12982   pt: 12982   cp: 12982   ct: 12982   lbp: 12997  bp: 12997   BP: 12986  BS: 1   lBS: 1   PP: 12981    (12986): < echo 4 > is SIMPLE FORK
pp: 12982   pt: 12982   cp: 12996   ct: 12982   lbp: 12994  bp: 12994   BP: 12996  BS: 2   lBS: 1   PP: 12981    (12996): < pid: 12996 > is BACKGROUND FORK
pp: 12982   pt: 12982   cp: 12997   ct: 12982   lbp: 12996  bp: 12996   BP: 12997  BS: 2   lBS: 1   PP: 12981    (12997): < pid: 12997 > is BACKGROUND FORK
pp: 12982   pt: 12982   cp: 12982   ct: 12982   lbp: 12997  bp: 12997   BP: 12986  BS: 1   lBS: 1   PP: 12981    (12986): < : > is NORMAL COMMAND
9
10
pp: 12996   pt: 12982   cp: 12996   ct: 12982   lbp: 12998  bp: 12998   BP: 12996  BS: 2   lBS: 2   PP: 12981    (12996): < echo 9 > is NORMAL COMMAND
pp: 12997   pt: 12982   cp: 12997   ct: 12982   lbp: 12999  bp: 12999   BP: 12997  BS: 2   lBS: 2   PP: 12981    (12997): < echo 10 > is NORMAL COMMAND
pp: 12982   pt: 12982   cp: 12982   ct: 12982   lbp: 12997  bp: 12997   BP: 12986  BS: 1   lBS: 1   PP: 12981    (12986): < wait > is NORMAL COMMAND

EOF

























######################################################################################
####################################### OLD ##########################################

(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid

: &
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=''

trap ':' EXIT

trap 'is_bg=false; is_subshell=false;
(( last_subshell == BASH_SUBSHELL )) || { is_subshell=true; last_subshell=$BASH_SUBSHELL; trap '"'"':'"'"' EXIT; }
(( last_bg_pid == $! )) || { is_bg=true; last_bg_pid=$!; }
if ${is_subshell}; then
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
  (( child_pgid == parent_pgid )) || { is_bg=true; parent_pgid=$child_pgid; parent_tpid=$child_tpid; }
fi
printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  PP: %s   PPP: %s    '"'"'  $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID $PPID $$
if ${is_subshell} && ${is_bg}; then
  printf '"'"'(%s): < %s > is %s\n'"'"' "$BASHPID" "" "BACKGROUND FORK"
elif ${is_subshell}; then
  printf '"'"'(%s): < %s > is %s\n'"'"' "$BASHPID" "" "SUBSHELL"
elif ${is_bg}; then
  [[ $last_command ]] && printf '"'"'(%s): < %s > is %s\n'"'"' "$BASHPID" "$last_command" "SIMPLE FORK"
else
  [[ $last_command ]] && printf '"'"'(%s): < %s > is %s\n'"'"' "$BASHPID" "$last_command" "NORMAL COMMAND"
fi >&$fd
last_command="$BASH_COMMAND"' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
:

) {fd}>&2


# gives
: <<'EOF'
pp: 14959   pt: 14959   cp: 14959   ct: 14964   lbp: 14964  bp: 14963   BP: 14958  PP: 14959   PPP:     0
pp: 14959   pt: 14959   cp: 14959   ct: 14964   lbp: 14964  bp: 14963   BP: 14958  PP: 14959   PPP:     (14963): < echo 0 > is NORMAL COMMAND
1
pp: 14965   pt: 14965   cp: 14965   ct: 14965   lbp: 14964  bp: 14964   BP: 14965  PP: 14958   PPP: 14959    (14965): <  > is BACKGROUND FORK
2
pp: 14965   pt: 14965   cp: 14965   ct: 14965   lbp: 14964  bp: 14964   BP: 14965  PP: 14958   PPP: 14959    (14965): < echo 2 > is NORMAL COMMAND
pp: 14959   pt: 14959   cp: 14959   ct: 14964   lbp: 14964  bp: 14963   BP: 14958  PP: 14959   PPP:     (14963): < echo 1 > is NORMAL COMMAND
3
pp: 14959   pt: 14959   cp: 14959   ct: 14966   lbp: 14966  bp: 14963   BP: 14958  PP: 14959   PPP:     (14963): < echo 3 > is SIMPLE FORK
4
pp: 14968   pt: 14969   cp: 14968   ct: 14969   lbp: 14967  bp: 14967   BP: 14968  PP: 14958   PPP: 14959    (14968): <  > is BACKGROUND FORK
5
pp: 14969   pt: 14969   cp: 14969   ct: 14969   lbp: 14968  bp: 14968   BP: 14969  PP: 14958   PPP: 14959    (14969): <  > is BACKGROUND FORK
pp: 14968   pt: 14969   cp: 14968   ct: 14969   lbp: 14967  bp: 14967   BP: 14968  PP: 14958   PPP: 14959    (14968): < echo 5 > is NORMAL COMMAND
6
pp: 14969   pt: 14969   cp: 14969   ct: 14969   lbp: 14970  bp: 14970   BP: 14969  PP: 14958   PPP: 14959    (14969): < echo 6 > is SIMPLE FORK
pp: 14971   pt: 14972   cp: 14971   ct: 14972   lbp: 14968  bp: 14968   BP: 14971  PP: 14958   PPP: 14959    (14971): <  > is BACKGROUND FORK
7
pp: 14971   pt: 14972   cp: 14971   ct: 14972   lbp: 14968  bp: 14968   BP: 14971  PP: 14958   PPP: 14959    (14971): < echo 7 > is NORMAL COMMAND
pp: 14972   pt: 14972   cp: 14972   ct: 14972   lbp: 14971  bp: 14971   BP: 14972  PP: 14958   PPP: 14959    (14972): <  > is BACKGROUND FORK
8
pp: 14972   pt: 14972   cp: 14972   ct: 14972   lbp: 14971  bp: 14971   BP: 14972  PP: 14958   PPP: 14959    (14972): < echo 8 > is NORMAL COMMAND
pp: 14959   pt: 14959   cp: 14959   ct: 14971   lbp: 14971  bp: 14963   BP: 14958  PP: 14959   PPP:     (14963): < echo 4 > is SIMPLE FORK
pp: 14959   pt: 14959   cp: 14959   ct: 14971   lbp: 14971  bp: 14963   BP: 14958  PP: 14959   PPP:     (14963): < : > is NORMAL COMMAND

EOF



####################################

#                             Online Bash Shell.
#                 Code, Compile, Run and Debug Bash script online.
# Write your code in this editor and press "Run" button to execute it.

(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=''
subshell_pid=''

trap ':' EXIT

trap 'is_bg=false; is_subshell=false;
(( last_subshell == BASH_SUBSHELL )) || { is_subshell=true; last_subshell=$BASH_SUBSHELL; subshell_pid=$BASHPID; trap '"'"':'"'"' EXIT; }
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
if ${is_subshell} || (( subshell_pid == BASHPID )); then
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) ||  is_bg=true
elif ! ${is_subshell} && (( last_bg_pid == $! )); then
  is_bg=true; last_bg_pid=$!
fi
if ${is_subshell} && ${is_bg}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$PPID" "$BASHPID" "pid: $BASHPID" "BACKGROUND FORK"
elif ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$PPID" "$BASHPID" "pid: $BASHPID" "SUBSHELL"
elif ${is_bg}; then
  if   (( parent_pgid != parent_tpid )); then
    [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$PPID" "$BASHPID" "$last_command" "SUBSHELL"
  else
    [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$PPID" "$BASHPID" "$last_command" "SIMPLE FORK"
  fi
else
  [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$PPID" "$BASHPID" "$last_command" "NORMAL COMMAND"
fi >&$fd
last_command="$BASH_COMMAND"
{ ${is_bg} || ${is_subshell}; } && {
 parent_pgid=$child_pgid
 parent_tpid=$child_tpid
 }' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
:
wait

) {fd}>&2


:<<'EOF'
0
pp: 7022   pt: 7022   cp: 7022   ct: 7022   lbp: 7027  bp: 7027   BP: 7026  BS: 1   PP: 7021    (7026): < echo 0 > is SIMPLE FORK
1
pp: 7022   pt: 7022   cp: 7028   ct: 7028   lbp: 7027  bp: 7027   BP: 7028  BS: 2   PP: 7021    (7028): < pid: 7028 > is SUBSHELL
2
pp: 7028   pt: 7028   cp: 7028   ct: 7028   lbp: 7027  bp: 7027   BP: 7028  BS: 2   PP: 7021    (7028): < echo 2 > is NORMAL COMMAND
pp: 7022   pt: 7022   cp: 7022   ct: 7022   lbp: 7027  bp: 7027   BP: 7026  BS: 1   PP: 7021    (7026): < echo 1 > is SIMPLE FORK
3
pp: 7022   pt: 7022   cp: 7022   ct: 7022   lbp: 7027  bp: 7029   BP: 7026  BS: 1   PP: 7021    (7026): < echo 3 > is NORMAL COMMAND
4
pp: 7022   pt: 7022   cp: 7031   ct: 7032   lbp: 7027  bp: 7030   BP: 7031  BS: 2   PP: 7021    (7031): < pid: 7031 > is BACKGROUND FORK
5
pp: 7022   pt: 7022   cp: 7032   ct: 7032   lbp: 7027  bp: 7031   BP: 7032  BS: 2   PP: 7021    (7032): < pid: 7032 > is SUBSHELL
pp: 7031   pt: 7032   cp: 7031   ct: 7032   lbp: 7027  bp: 7030   BP: 7031  BS: 2   PP: 7021    (7031): < echo 5 > is SUBSHELL
6
pp: 7032   pt: 7032   cp: 7032   ct: 7032   lbp: 7027  bp: 7033   BP: 7032  BS: 2   PP: 7021    (7032): < echo 6 > is NORMAL COMMAND
pp: 7022   pt: 7022   cp: 7034   ct: 7035   lbp: 7027  bp: 7031   BP: 7034  BS: 2   PP: 7021    (7034): < pid: 7034 > is BACKGROUND FORK
7
pp: 7022   pt: 7022   cp: 7035   ct: 7035   lbp: 7027  bp: 7034   BP: 7035  BS: 2   PP: 7021    (7035): < pid: 7035 > is SUBSHELL
8
pp: 7034   pt: 7035   cp: 7034   ct: 7035   lbp: 7027  bp: 7031   BP: 7034  BS: 2   PP: 7021    (7034): < echo 7 > is SUBSHELL
pp: 7035   pt: 7035   cp: 7035   ct: 7035   lbp: 7027  bp: 7034   BP: 7035  BS: 2   PP: 7021    (7035): < echo 8 > is NORMAL COMMAND
pp: 7022   pt: 7022   cp: 7022   ct: 7022   lbp: 7027  bp: 7034   BP: 7026  BS: 1   PP: 7021    (7026): < echo 4 > is NORMAL COMMAND
pp: 7022   pt: 7022   cp: 7022   ct: 7022   lbp: 7027  bp: 7034   BP: 7026  BS: 1   PP: 7021    (7026): < : > is NORMAL COMMAND
pp: 7022   pt: 7022   cp: 7022   ct: 7022   lbp: 7027  bp: 7034   BP: 7026  BS: 1   PP: 7021    (7026): < wait > is NORMAL COMMAND

EOF


##########################################################

#                             Online Bash Shell.
#                 Code, Compile, Run and Debug Bash script online.
# Write your code in this editor and press "Run" button to execute it.

(

set -T
set -m

read -r _ _ _ _ parent_pgid _ _ parent_tpid _ </proc/${BASHPID}/stat
child_pgid=$parent_pgid
child_tpid=$parent_tpid

: &
last_bg_pid=$!
last_subshell=$BASH_SUBSHELL
last_command=''
subshell_pid=''

trap ':' EXIT

trap 'is_bg=false; is_subshell=false;
(( last_subshell == BASH_SUBSHELL )) || { is_subshell=true; subshell_pid=$BASHPID; trap '"'"':'"'"' EXIT; }
  read -r _ _ _ _ child_pgid _ _ child_tpid _ </proc/${BASHPID}/stat
if ${is_subshell} || (( subshell_pid == BASHPID )); then
  (( child_pgid == parent_tpid )) || (( child_pgid == child_tpid )) ||  is_bg=true
fi
(( last_bg_pid == $! )) || is_bg=true; last_bg_pid=$!
if ${is_subshell} && ${is_bg}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "pid: $BASHPID" "BACKGROUND FORK"
elif ${is_subshell}; then
  printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "pid: $BASHPID" "SUBSHELL"
elif ${is_bg}; then
  if   (( parent_pgid != parent_tpid )); then
    [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "$last_command" "NORMAL COMMAND"
  else
    [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "$last_command" "SIMPLE FORK"
  fi
else
  [[ $last_command ]] && printf '"'"'pp: %s   pt: %s   cp: %s   ct: %s   lbp: %s  bp: %s   BP: %s  BS: %s   lBS: %s   PP: %s    (%s): < %s > is %s\n'"'"' $parent_pgid $parent_tpid $child_pgid $child_tpid $last_bg_pid $! $BASHPID "$BASH_SUBSHELL" "$last_subshell" "$PPID" "$BASHPID" "$last_command" "NORMAL COMMAND"
fi >&$fd
last_command="$BASH_COMMAND"
${is_subshell} && last_subshell=$BASH_SUBSHELL
{ ${is_bg} || ${is_subshell}; } && {
 parent_pgid=$child_pgid
 parent_tpid=$child_tpid
 }' DEBUG

echo 0
{ echo 1; }
( echo 2 )
echo 3 &
{ echo 4 & }
{ echo 5; } &
( echo 6 & )
( echo 7 ) &
( echo 8 )
( echo 9 & ) &
:
wait

) {fd}>&2

:<<'EOF
0
pp: 17626   pt: 17626   cp: 17626   ct: 17626   lbp: 17631  bp: 17631   BP: 17630  BS: 1   lBS: 1   PP: 17625    (17630): < echo 0 > is NORMAL COMMAND
1
pp: 17626   pt: 17626   cp: 17632   ct: 17632   lbp: 17631  bp: 17631   BP: 17632  BS: 2   lBS: 1   PP: 17625    (17632): < pid: 17632 > is SUBSHELL
2
pp: 17632   pt: 17632   cp: 17632   ct: 17632   lbp: 17631  bp: 17631   BP: 17632  BS: 2   lBS: 2   PP: 17625    (17632): < echo 2 > is NORMAL COMMAND
pp: 17626   pt: 17626   cp: 17626   ct: 17626   lbp: 17631  bp: 17631   BP: 17630  BS: 1   lBS: 1   PP: 17625    (17630): < echo 1 > is NORMAL COMMAND
3
pp: 17626   pt: 17626   cp: 17626   ct: 17626   lbp: 17633  bp: 17633   BP: 17630  BS: 1   lBS: 1   PP: 17625    (17630): < echo 3 > is SIMPLE FORK
4
pp: 17626   pt: 17626   cp: 17635   ct: 17636   lbp: 17634  bp: 17634   BP: 17635  BS: 2   lBS: 1   PP: 17625    (17635): < pid: 17635 > is BACKGROUND FORK
5
pp: 17626   pt: 17626   cp: 17636   ct: 17636   lbp: 17635  bp: 17635   BP: 17636  BS: 2   lBS: 1   PP: 17625    (17636): < pid: 17636 > is BACKGROUND FORK
pp: 17635   pt: 17636   cp: 17635   ct: 17636   lbp: 17634  bp: 17634   BP: 17635  BS: 2   lBS: 2   PP: 17625    (17635): < echo 5 > is NORMAL COMMAND
6
pp: 17636   pt: 17636   cp: 17636   ct: 17636   lbp: 17637  bp: 17637   BP: 17636  BS: 2   lBS: 2   PP: 17625    (17636): < echo 6 > is SIMPLE FORK
pp: 17626   pt: 17626   cp: 17638   ct: 17639   lbp: 17635  bp: 17635   BP: 17638  BS: 2   lBS: 1   PP: 17625    (17638): < pid: 17638 > is BACKGROUND FORK
7
pp: 17626   pt: 17626   cp: 17639   ct: 17639   lbp: 17638  bp: 17638   BP: 17639  BS: 2   lBS: 1   PP: 17625    (17639): < pid: 17639 > is BACKGROUND FORK
pp: 17638   pt: 17639   cp: 17638   ct: 17639   lbp: 17635  bp: 17635   BP: 17638  BS: 2   lBS: 2   PP: 17625    (17638): < echo 7 > is NORMAL COMMAND
8
pp: 17639   pt: 17639   cp: 17639   ct: 17639   lbp: 17638  bp: 17638   BP: 17639  BS: 2   lBS: 2   PP: 17625    (17639): < echo 8 > is NORMAL COMMAND
pp: 17626   pt: 17626   cp: 17626   ct: 17626   lbp: 17640  bp: 17640   BP: 17630  BS: 1   lBS: 1   PP: 17625    (17630): < echo 4 > is SIMPLE FORK
pp: 17626   pt: 17626   cp: 17626   ct: 17626   lbp: 17640  bp: 17640   BP: 17630  BS: 1   lBS: 1   PP: 17625    (17630): < : > is NORMAL COMMAND
pp: 17626   pt: 17626   cp: 17640   ct: 17626   lbp: 17638  bp: 17638   BP: 17640  BS: 2   lBS: 1   PP: 17625    (17640): < pid: 17640 > is BACKGROUND FORK
9
pp: 17640   pt: 17626   cp: 17640   ct: 17626   lbp: 17641  bp: 17641   BP: 17640  BS: 2   lBS: 2   PP: 17625    (17640): < echo 9 > is NORMAL COMMAND
pp: 17626   pt: 17626   cp: 17626   ct: 17626   lbp: 17640  bp: 17640   BP: 17630  BS: 1   lBS: 1   PP: 17625    (17630): < wait > is NORMAL COMMAND
EOF
