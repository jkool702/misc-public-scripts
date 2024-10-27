#!/usr/bin/env bash

sensors_t() {
## uses sensors (from lm_sensors) to display CPU temps and keep track of maximum temps encountered
# 
# USAGE: sensors_t [N] [CHIP(S)]
#            N: (optional) length of time to sleep between updates in seconds. MUST be the 1st input. DEFAULT is N=1
#     CHIPS(S): (optional) the chip(s) to have sensors display sensors for. example: "coretemp-isa-0000". Default is to omit this, causing all sensors data to display.
#   USAGE NOTE: "sensors_t" is a bash function. The source file ("sensors_t.bash") must be sourced before sensors_t can be used
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
        local -a t_max t_cur t_cur_cpu sensorsArgs
        local tmpStr t_max_cpu g_cur nn nvidiaFlag
        local -i sleepTime

        # get how long to sleep between updates
        (( ${1} > 0 )) && { sleepTime=${1}; shift 1; } || sleepTime=1

        # reset bash timer
        SECONDS=0

        # determine if we have nvidia-smi 
        type nvidia-smi &>/dev/null && nvidiaFlag=true || nvidiaFlag=false

        # start main loop
        while true; do

            # get CPU (and GPU) temps afrom sensors and tweak the output to display how we want
            tmpStr="$(printf '\n----------------\n'; sensors "${@##-*}" | grep -B 1 -E '°C|RPM|Adapter' | grep -E '^[^[:space:]]' | sed -E 's/\-\-/\n----------------/; s/Adapter.*$/----------------/;s/°C[[:space:]]*(\(.*)?$/°C  \( MAX = %s )/')"; 

            # remove sensors without any valid output
            tmpStr="$(sed -E 's/'$'\034''\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-'$'\034''[^'$'\034'']+'$'\034''\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-'$'\034\034''/'$'\034''/g;s/'$'\034''/\n/g' <<<"${tmpStr//$'\n'/$'\034'}")"

            # extract the actual temps from the full text output
            mapfile -t t_cur < <(grep -F '%s'  <<<"${tmpStr}" | sed -E 's/^[^+-]*([+-])/\1/; s/C.*$/C/');
            mapfile -t t_cur_cpu < <(grep -F '%s'  <<<"${tmpStr}" | grep -E '^(Package|Core)' | sed -E 's/^[^+-]*([+-])/\1/; s/C.*$/C/');

            # get current max CPU temp and add it to the output string / array of current temps
            t_max_cpu="$(IFS=$'\n'; sort -n <<<"${t_cur_cpu[*]}" | tail -n 1)"; 
            tmpStr+=$'\n\n''----------------'$'\n''Additional Temps'$'\n''----------------'$'\n\n''CPU HOT TEMP: '"${t_max_cpu}"'  ( CPU HOT MAX = %s )'$'\n'; 
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

            # print a seperator and then the temps
            printf '\n___________________________________________\n___________________________________________\n\nMonitor has been running for:  %s seconds\n-------------------------------------------\n'"${tmpStr}"'\n----------------\n----------------\n' "${SECONDS}"  "${t_max[@]}"


            # sleep for sleepTime seconds
            read -r -u ${fd_sleep} -t ${sleepTime}
        done
    ) {fd_sleep}<><(:)
}

: <<EOF
# EXAMPLE OUTPUT "PAGE"

___________________________________________
___________________________________________

Monitor has been running for:  173 seconds
-------------------------------------------

----------------
coretemp-isa-0000
----------------
Package id 0:  +46.0°C  ( MAX = +98.0°C )
Core 0:        +46.0°C  ( MAX = +81.0°C )
Core 1:        +46.0°C  ( MAX = +88.0°C )
Core 2:        +48.0°C  ( MAX = +87.0°C )
Core 3:        +45.0°C  ( MAX = +98.0°C )
Core 4:        +43.0°C  ( MAX = +91.0°C )
Core 5:        +45.0°C  ( MAX = +99.0°C )
Core 6:        +45.0°C  ( MAX = +82.0°C )
Core 8:        +44.0°C  ( MAX = +84.0°C )
Core 9:        +43.0°C  ( MAX = +90.0°C )
Core 10:       +43.0°C  ( MAX = +93.0°C )
Core 11:       +44.0°C  ( MAX = +80.0°C )
Core 12:       +43.0°C  ( MAX = +93.0°C )
Core 13:       +46.0°C  ( MAX = +79.0°C )
Core 14:       +44.0°C  ( MAX = +81.0°C )

----------------
kraken2-hid-3-1
----------------
Fan:            0 RPM
Pump:        2826 RPM
Coolant:      +45.1°C  ( MAX = +45.4°C )

----------------
nvme-pci-0c00
----------------
Composite:    +42.9°C  ( MAX = +46.9°C )

----------------
enp10s0-pci-0a00
----------------
MAC Temperature:  +53.9°C  ( MAX = +59.3°C )

----------------
nvme-pci-b300
----------------
Composite:    +40.9°C  ( MAX = +42.9°C )
Sensor 1:     +40.9°C  ( MAX = +42.9°C )
Sensor 2:     +42.9°C  ( MAX = +48.9°C )

----------------
nvme-pci-0200
----------------
Composite:    +37.9°C  ( MAX = +39.9°C )

----------------
Additional Temps
----------------

CPU HOT TEMP: +48.0°C  ( CPU HOT MAX = +99.0°C )

GPU TEMP:     +36°C  ( GPU MAX = 39°C )

----------------
----------------
EOF
