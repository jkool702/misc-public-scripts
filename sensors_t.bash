#!/usr/bin/env bash

sensors_t() {
	(
		local -a t_max t_cur
		local tmpStr t_max_cpu nn nvidiaFlag liquidctlFlag liquidctlName

		SECONDS=0

		type nvidia-smi &>/dev/null && nvidiaFlag=true || nvidiaFlag=false
		type liquidctl &>/dev/null && liquidctlFlag=true || liquidctlFlag=false
		${liquidctlFlag} && liquidctlName="$(printf '\nAIO: %s\n' "$(liquidctl list | head -n 1 | sed -E s/'^.*\:'//)";)"

		while true; do
			tmpStr="$(${nvidiaFlag} && printf 'GPU TEMP:      +%s  ( GPU MAX = %%s )\n' "$(nvidia-smi | grep -oE '[0-9]+C' | sed -E s/'C'/'°C'/)"; sensors | grep -iE "core|package"  | grep -vF "coretemp-isa-0000" | sed -E 's/\(.*$/\( MAX = %s )/; s/\.0//g')"; 
			mapfile -t t_cur < <(sed -E 's/^[^+-]*([+-])/\1/; s/C.*$/C/' <<<"${tmpStr}");
   
			t_max_cpu="$(IFS=$'\n'; sort -n <<<"${t_cur[*]:1}" | tail -n 1)"; 
			tmpStr+=$'\n''CORE MAX:      '"${t_max_cpu}"'  ( CPU MAX = %s )'$'\n'; 
			t_cur+=("${t_max_cpu}"); 
   
			[[ ${#t_max[@]} == 0 ]] && t_max=("${t_cur[@]}") || for nn in "${!t_cur[@]}"; do 
				(( ${t_cur[$nn]//[^0-9]/} > ${t_max[$nn]//[^0-9]/} )) && t_max[$nn]="${t_cur[$nn]}"; 
			done; 

			printf '||---------------------------------------||\n\nMonitor has been running for:  %s seconds\n\n' "${SECONDS}"

			${nvidiaFlag} && tmpStr="${tmpStr/$'\n'/$'\n\n'}"
			printf "${tmpStr}" "${t_max[@]}"

			${liquidctlFlag} && { printf '%s\n' "${liquidctlName}"; liquidctl status | grep -iE "pump|temp"; }

			printf '\n';

			read -r -u ${fd_sleep} -t 1
		done
	) {fd_sleep}<><(:)
}
