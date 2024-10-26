#!/usr/bin/env bash

sensors_t() {
## uses sensors (from lm_sensors) to display CPU temps and keep track of maximum temps encountered
# 
# USAGE: sensors_t [N]
#     N: length of time to sleep between updates in seconds. DEFAULT is N=1
#  NOTE: "sensors_t" is a bash function. sensos_t.bash must be sourced before sensors_t can be used
#
# IF AVAILABLE: nvidia-smi will be used to display nvidia GPU temps
#
# DEPENDENCIES: bash 4+, sensors (from lm_sensors), sed, grep, tail, head

    # check for sensors support
    sensors &>/dev/null || sensors-detect || {
        printf '\nERROR: this system does not currently support "sensors". ABORTING!!!\n\n'
        return 1
    }

    (
        # make vars local
        local -a t_max t_cur t_cur_cpu
        local tmpStr t_max_cpu g_cur nn nvidiaFlag
        local -i kk sleepTime

        # get how long to sleep between 
        sleepTime=1
        (( ${#} > 0 )) && for kk in "${@}"; do
            (( kk > 0 )) && sleepTime=${kk} && break
        done

        # reset bash timer
        SECONDS=0

        # determine if we have nvidia-smi 
        type nvidia-smi &>/dev/null && nvidiaFlag=true || nvidiaFlag=false

        # start main loop
        while true; do

            # get CPU (and GPU) temps afrom sensors and tweak the output to display how we want
            tmpStr="$(printf '\n----------------\n'; sensors | grep -B 1 -E '°C|RPM|Adapter' | grep -E '^[^[:space:]]' | sed -E 's/\-\-/\n----------------/; s/Adapter.*$/----------------/;s/°C[[:space:]]*(\(.*)?$/°C  \( MAX = %s )/')"; 

            # extract the actual temps from the full text output
            mapfile -t t_cur < <(grep -F '%s'  <<<"${tmpStr}" | sed -E 's/^[^+-]*([+-])/\1/; s/C.*$/C/');
            mapfile -t t_cur_cpu < <(grep -F '%s'  <<<"${tmpStr}" | grep -E '^(Package|Core)' | sed -E 's/^[^+-]*([+-])/\1/; s/C.*$/C/');

            # get current max CPU temp and add it to the output string / array of current temps
            t_max_cpu="$(IFS=$'\n'; sort -n <<<"${t_cur_cpu[*]}" | tail -n 1)"; 
            tmpStr+=$'\n\n''----------------'$'\n''----------------'$'\n\n''CPU HOT TEMP: '"${t_max_cpu}"'  ( CPU HOT MAX = %s )'$'\n'; 
            t_cur+=("${t_max_cpu}"); 

            # get GPU temp
            ${nvidiaFlag} && {
                g_cur="$(nvidia-smi | grep -oE '[0-9]+C' | sed -E s/'C'/'°C'/)"
                tmpStr+=$'\n''GPU TEMP:     +'"${g_cur}"'  ( GPU MAX = %s )'$'\n'
                t_cur+=("${g_cur}");
            } 

            # update the maximum recorded temperature for each sensor if current temp is higher than recorded maximum temp
            [[ ${#t_max[@]} == 0 ]] && t_max=("${t_cur[@]}") || for nn in "${!t_cur[@]}"; do 
                (( ${t_cur[$nn]//[^0-9]/} > ${t_max[$nn]//[^0-9]/} )) && t_max[$nn]="${t_cur[$nn]}"; 
            done; 

            # print a seperator
            printf '||---------------------------------------||\n\nMonitor has been running for:  %s seconds\n\n' "${SECONDS}"

            # print CPU (and GPU) temps
            printf "${tmpStr}"'\n' "${t_max[@]}"

            # sleep for sleepTime seconds
            read -r -u ${fd_sleep} -t ${sleepTime}
        done
    ) {fd_sleep}<><(:)
}
