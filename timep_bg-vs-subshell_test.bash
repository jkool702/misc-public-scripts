
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
