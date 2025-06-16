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
