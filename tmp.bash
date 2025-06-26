#!/bin/bash

[[ "$-" == *m* ]] || {
  printf '\nWARNING: timep requires job control to be enabled.\n         Running "set +m" is not allowed!\n         Job control will automatically be re-enabled.\n\n' >&2
  set -m
}
[[ "${BASH_COMMAND}" == trap\ * ]] && {
  timep_SKIP_DEBUG_FLAG=true
  (( timep_FNEST_CUR == ${#FUNCNAME[@]} )) && {
    timep_FNEST+=("${#FUNCNAME[@]}")
    timep_FUNCNAME_STR+=".trap"
    timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
    timep_NEXEC_A+=("0")
    (( timep_NEXEC_N++ ))
  }
}
${timep_SKIP_DEBUG_FLAG} || {
timep_NPIPE[${timep_FNEST_CUR}]=${timep_NPIPE0}
timep_ENDTIME=${timep_ENDTIME0}
timep_IS_BG_FLAG=false
timep_IS_SUBSHELL_FLAG=false
timep_IS_FUNC_FLAG=false
if ${timep_SIMPLEFORK_NEXT_FLAG}; then
  timep_SIMPLEFORK_NEXT_FLAG=false
  timep_SIMPLEFORK_CUR_FLAG=true
else
  timep_SIMPLEFORK_CUR_FLAG=false
fi
if (( timep_BASH_SUBSHELL_PREV == BASH_SUBSHELL )); then
  if (( timep_BG_PID_PREV == $! )); then
    (( timep_FNEST_CUR >= ${#FUNCNAME[@]} )) || {
      timep_IS_FUNC_FLAG=true
      timep_NO_PRINT_FLAG=true
      timep_FNEST+=("${#FUNCNAME[@]}")
    }
  else
    timep_IS_BG_FLAG=true
  fi
else
  timep_IS_SUBSHELL_FLAG=true
  echo "${timep_ENDTIME}" >>"${timep_TMPDIR}/.log/.endtimes/${timep_NEXEC_0}.${timep_NEXEC_A[-1]}"
  (( BASHPID < timep_BASHPID_PREV )) && (( timep_NPIDWRAP++ ))
  builtin trap ':' EXIT
  IFS=' '  read -r _ _ _ _ timep_CHILD_PGID _ _ timep_CHILD_TPID _ </proc/${BASHPID}/stat
  (( timep_CHILD_PGID == timep_PARENT_TPID )) || (( timep_CHILD_PGID == timep_CHILD_TPID )) || { (( timep_CHILD_PGID == timep_PARENT_PGID )) && (( timep_CHILD_TPID == timep_PARENT_TPID )); } || timep_IS_BG_FLAG=true
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
      timep_BASH_SUBSHELL_DIFF_0="${timep_BASH_SUBSHELL_DIFF}"
      (( timep_BASH_SUBSHELL_DIFF-- ))
      case "${timep_KK}" in
        0) timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}]="${BASHPID}" ;;
        *) IFS=" " read -r _ _ _ timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}] _ </proc/${timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF_0}]}/stat ;;
      esac
      if (( timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}] == timep_BASHPID_PREV )) || (( timep_BASHPID_ADD[${timep_BASH_SUBSHELL_DIFF}] <= 1 )); then
        (( timep_BASH_SUBSHELL_DIFF++ ))
        (( timep_BASH_SUBSHELL_DIFF_0++ ))
        break
      else
        (( timep_KK++ ))
      fi
    done
    timep_KK="${timep_BASH_SUBSHELL_DIFF}"
    unset "timep_BASH_SUBSHELL_DIFF" "timep_BASH_SUBSHELL_DIFF_0"
    (( timep_NEXEC_N++ ))
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
    timep_LINENO[${timep_FNEST_CUR}]="${LINENO}"
    ${timep_NO_PRINT_FLAG} || printf '%s\t%s\t-\tF:%s %s\tS:%s %s\tN:%s %s.%s[%s-%s]\t%s\t::\t'"'"'<< (%s): %s >>'"'"'\n' "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_ENDTIME}"  "${timep_FNEST_CUR}" "${timep_FUNCNAME_STR}" "${BASH_SUBSHELL}" "${timep_BASHPID_STR}" "${timep_NEXEC_N}" "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_NPIDWRAP}" "${BASHPID}" "${timep_LINENO[${timep_FNEST_CUR}]}" "${timep_CMD_TYPE}" "${timep_BASHPID_PREV}" >>"${timep_TMPDIR}/.log/log.${timep_NEXEC_0}"
    timep_BASHPID_STR+=".${timep_BASHPID_PREV}"
    timep_NEXEC_0+=".${timep_NEXEC_A[-1]}[${timep_NPIDWRAP}-${timep_BASHPID_PREV}]"
    timep_NEXEC_A+=(0)
    (( timep_NEXEC_N++ ))
    timep_PARENT_PGID="$timep_CHILD_PGID"
  timep_PARENT_TPID="$timep_CHILD_TPID"
  timep_BASH_SUBSHELL_PREV="$BASH_SUBSHELL"
elif [[ ${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]} ]]; then
  ${timep_SIMPLEFORK_CUR_FLAG} && (( BASHPID < $! )) && ! ${timep_IS_FUNC_FLAG} && {
    timep_IS_BG_FLAG=true
    timep_CMD_TYPE="SIMPLE FORK *"
  }
  if ${timep_IS_BG_FLAG}; then
     timep_IS_BG_INDICATOR='(&)'
  else
     timep_IS_BG_INDICATOR=''
  fi
  [[ -s "${timep_TMPDIR}/.log/.endtimes/${timep_NEXEC_0}.${timep_NEXEC_A[-1]}" ]] && {
    {
      while read -r -u ${timep_FD} timep_ENDTIME0; do
        (( ${timep_ENDTIME0//./} < ${timep_ENDTIME//./} )) && timep_ENDTIME="${timep_ENDTIME0}"
      done
    } {timep_FD}<"${timep_TMPDIR}/.log/.endtimes/${timep_NEXEC_0}.${timep_NEXEC_A[-1]}"
    exec {timep_FD}>&-
  }
  ${timep_NO_PRINT_FLAG} || printf '%s\t%s\t%s\tF:%s %s\tS:%s %s\tN:%s %s.%s\t%s\t::\t%s %s\n' "${timep_NPIPE[${timep_FNEST_CUR}]}" "${timep_STARTTIME[${timep_FNEST_CUR}]}" "${timep_ENDTIME}" "${timep_FNEST_CUR}" "${timep_FUNCNAME_STR}" "${BASH_SUBSHELL}" "${timep_BASHPID_STR}" "${timep_NEXEC_N}"  "${timep_NEXEC_0}" "${timep_NEXEC_A[-1]}" "${timep_LINENO[${timep_FNEST_CUR}]}" "${timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]@Q}" "${timep_IS_BG_INDICATOR}" >>"${timep_TMPDIR}/.log/log.${timep_NEXEC_0}"
  (( timep_NEXEC_A[-1]++ ))
  (( timep_NEXEC_N++ ))
fi
${timep_IS_FUNC_FLAG} && {
  timep_FUNCNAME_STR+=".${FUNCNAME[0]}"
  timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
  timep_NEXEC_A+=(0)
  (( timep_NEXEC_N++ ))
  timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]=" (F) << (FUNCTION): ${BASH_COMMAND} >>"
  timep_LINENO[${timep_FNEST_CUR}]="${LINENO}"
  timep_NPIPE[${#FUNCNAME[@]}]="${timep_NPIPE[${timep_FNEST_CUR}]}"
  timep_FNEST_CUR="${#FUNCNAME[@]}"
  timep_NO_PRINT_FLAG=false
  timep_IS_FUNC_FLAG_1=true
}
timep_BASH_COMMAND_PREV[${timep_FNEST_CUR}]="${BASH_COMMAND}"
timep_LINENO[${timep_FNEST_CUR}]="${LINENO}"
timep_BG_PID_PREV="$!"
timep_BASHPID_PREV="$BASHPID"
if [[ "$BASH_COMMAND" == exec* ]]; then
    timep_EXEC_ARG="${BASH_COMMAND#*[[:space:]]}"
    timep_EXEC_ARG="${BASH_COMMAND%%[[:space:]]*}"
    timep_EXEC_ARG="$(type -p "${timep_EXEC_ARG}")
    if [[ "${timep_EXEC_ARG}" == "${timep_BASH_PATH}" ]] || [[ "${timep_EXEC_ARG}" == "/bin/bash" ]] || [[ "${timep_EXEC_ARG}" == "/usr/bin/bash" ]]; then
        timep_SKIP_DEBUG_FLAG=true
        timep_FNEST+=("${timep_FNEST_CUR}")
        timep_FUNCNAME_STR+=".exec"
        timep_NEXEC_0+=".${timep_NEXEC_A[-1]}"
        timep_NEXEC_A+=("0")
        (( timep_NEXEC_N++ ))
exec() {
    export -f timep
    local -a cmd0=()
    shift 1
    while [[ "$1" == '-'* ]]; do
        case "$1" in
            -o|-O) { [[ "$1" == "-o" ]] && [[ "$2" == "monitor" ]]; } || { [[ "$1" == "-O" ]] && [[ "$2" == "extglob" ]]; } || cmd0+=("$1" "$2"); shift 2 ;;
            -c) shift 1; break ;;
            *) [[ "$1" == [+-]m ]] || [[ "$1" == [+-]i ]] || cmd0+=("$1"); shift 1 ;;
        esac
    done
    unset exec
    if [[ -t 0 ]]; then
        builtin exec "${BASH} -i -m -O extglob ${cmd0[@]} -c timep ${@}"
    else
        builtin exec "${BASH} -i -m -O extglob ${cmd0[@]} -c timep ${@}" <&0
    fi
}
    fi
fi
timep_STARTTIME[${timep_FNEST_CUR}]="${EPOCHREALTIME}"
}
