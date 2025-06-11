
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
