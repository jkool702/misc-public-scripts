#!/usr/bin/env bash

sensors_t() {
## uses sensors (from lm_sensors) to display CPU temps and keep track of maximum temps encountered
# 
# USAGE: sensors_t [N]
#     N: length of time to sleep between updates in seconds. DEFAULT is N=1
#  NOTE: sensors_t is a bash function. sensos_t.bash must be sourced before sensors_t can be used
#
# IF AVAILABLE: liquidctl and nvidia-smi will be used to display AIO temps and nvidia GPOU temps
#
# DEPENDENCIES: bash 4+, sensors (from lm_sensors), sed, grep. tail, head

    # check for sensors support
    sensors &>/dev/null || sensors-detect || {
        printf '\nERROR: this system does not currently support "sensors". ABORTING!!!\n\n'
        return 1
    }

    (
        # make vars local
        local -a t_max t_cur
        local tmpStr t_max_cpu nn nvidiaFlag liquidctlFlag liquidctlName
        local -i kk sleepTime

        # get how long to sleep between 
        sleepTime=1
        (( ${#} > 0 )) && for kk in "${@}"; do
            (( kk > 0 )) && sleepTime=${kk} && break
        done

        # reset bash timer
        SECONDS=0

        # determine if we have nvidia-smi and/or liquidctl
        type nvidia-smi &>/dev/null && nvidiaFlag=true || nvidiaFlag=false
        type liquidctl &>/dev/null && liquidctlFlag=true || liquidctlFlag=false
        ${liquidctlFlag} && liquidctlName="$(printf '\nAIO: %s\n' "$(liquidctl list | head -n 1 | sed -E s/'^.*\:'//)";)"

        # start main loop
        while true; do

            # get CPU (and GPU) temps afrom sensors and tweak the output to display how we want
            tmpStr="$(${nvidiaFlag} && printf 'GPU TEMP:      +%s  ( GPU MAX = %%s )\n' "$(nvidia-smi | grep -oE '[0-9]+C' | sed -E s/'C'/'°C'/)"; sensors | grep -iE "core|package"  | grep -vF "coretemp-isa-0000" | sed -E 's/\(.*$/\( MAX = %s )/; s/\.0//g')"; 

            # extract the actual temps from the full text output
            mapfile -t t_cur < <(sed -E 's/^[^+-]*([+-])/\1/; s/C.*$/C/' <<<"${tmpStr}");

            # get current max CPU temp and add it to the output string / array of current temps
            t_max_cpu="$(IFS=$'\n'; sort -n <<<"${t_cur[*]:$(${nvidiaFlag} && echo '1' || echo '0')}" | tail -n 1)"; 
            tmpStr+=$'\n''CORE MAX:      '"${t_max_cpu}"'  ( CPU MAX = %s )'$'\n'; 
            t_cur+=("${t_max_cpu}"); 

            # update the maximum recorded temperature for each sensor if current temp is higher than recorded maximum temp
            [[ ${#t_max[@]} == 0 ]] && t_max=("${t_cur[@]}") || for nn in "${!t_cur[@]}"; do 
                (( ${t_cur[$nn]//[^0-9]/} > ${t_max[$nn]//[^0-9]/} )) && t_max[$nn]="${t_cur[$nn]}"; 
            done; 

            # print a seperator
            printf '||---------------------------------------||\n\nMonitor has been running for:  %s seconds\n\n' "${SECONDS}"

            # print CPU (and GPU) temps
            ${nvidiaFlag} && tmpStr="${tmpStr/$'\n'/$'\n\n'}"
            printf "${tmpStr}" "${t_max[@]}"

            # if we have liquidctl print AIO temps and pump speed
            ${liquidctlFlag} && { printf '%s\n' "${liquidctlName}"; liquidctl status | grep -iE "pump|temp"; }

            printf '\n';

            # sleep for sleepTime seconds
            read -r -u ${fd_sleep} -t ${sleepTime}
        done
    ) {fd_sleep}<><(:)
}
