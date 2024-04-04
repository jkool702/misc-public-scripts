#!/usr/bin/env bash

read_speedtest() (

echo "BASE CASE: reading in variables directly from pipe"
( 
    for nn in {100000000..100000500}; do 
        linetype=$(( $RANDOM % 2 ));  
        case $linetype in 
            0) printf '%s a%s b%s c%s d%s\n' $linetype $nn $nn $nn $nn ;; 
            1) printf '%s z%s y%s x%s w%s v%s u%s t%s s%s r%s q%s p%s\n' $linetype $nn $nn $nn $nn $nn $nn $nn $nn $nn $nn $nn ;; 
        esac; 
        read -r -u $fdwait -t 0.01; 
    done; 
) {fdwait}<><(:) | ( 
    time { 
        while true; do
            read -r -d ' ' -u "$fd" || break
            case "${REPLY}" in 
                0) read -r -u "$fd" var1 dummy var2 dummy ;;
                1) read -r -u "$fd" var1 dummy var2 dummy var3 dummy var4 dummy var5 dummy var6<<<"${A[$kk]}" ;; 
            esac; 
        done;
    }  
) {fd}<&0

printf '\n-------------------------------\n'


echo "BASE CASE (alt): reading in variables directly from pipe to an array"
( 
    for nn in {100000000..100000500}; do 
        linetype=$(( $RANDOM % 2 ));  
        case $linetype in 
            0) printf '%s a%s b%s c%s d%s\n' $linetype $nn $nn $nn $nn ;; 
            1) printf '%s z%s y%s x%s w%s v%s u%s t%s s%s r%s q%s p%s\n' $linetype $nn $nn $nn $nn $nn $nn $nn $nn $nn $nn $nn ;; 
        esac; 
        read -r -u $fdwait -t 0.01; 
    done; 
) {fdwait}<><(:) | ( 
    time { 
        while true; do
            read -r -u "$fd" -a A || break
            case "${A[0]}" in 
                0) var1="${A[1]}" var3="${A[3]}" ;;
                1) var1="${A[1]}" var3="${A[3]}" var3="${A[3]}" var5="${A[5]}" var6="${A[6]}" ;; 
            esac 
        done;
    }  
) {fd}<&0

printf '\n-------------------------------\n'

echo "reading using a tmpfile (forkruns method - requires inotifywait and fallocate)"

    tdir=$(mktemp -d -p /dev/shm); : > ${tdir}/data
    touch "${tdir}"/data
( 
    for nn in {100000000..100000500}; do 
        linetype=$(( $RANDOM % 2 ));  
        case $linetype in 
            0) printf '%s a%s b%s c%s d%s\n' $linetype $nn $nn $nn $nn ;; 
            1) printf '%s z%s y%s x%s w%s v%s u%s t%s s%s r%s q%s p%s\n' $linetype $nn $nn $nn $nn $nn $nn $nn $nn $nn $nn $nn ;; 
        esac; 
        read -r -u $fdwait -t 0.01; 
    done; 
    touch "${tdir}"/done
    : >"${tdir}"/data
) {fdwait}<><(:) >"${tdir}"/data &
time { 
    (
        # attempt to truncate file(in 4096-byte blocks) every time this many lines are read
        fallocate_check_nlines0=4000
        
        # fork inotifywait to wattch tmpfile
        inotifywait -m -e modify --format='\n' >&"$fd_wait" "${tdir}"/data 2>/dev/null &
        pid_inotify="${!}"

        # loop until processes are finished
        stopFlag=false
        until $stopFlag && [[ ${#A[@]} == 0 ]]; do

            [[ -f "${tdir}"/done ]] && stopFlag=true

            # wait for inotifywait to tell you there is data
            $stopFlag || read -r -u "$fd_wait"

            # read all the data you can. NOTE: no -t flag keeps the delimiter. Wont work with NULL delimiter.
            read -r -u "$fd" -a A 
            case "${A[0]}" in 
                0) var1="${A[1]}" var3="${A[3]}" ;;
                1) var1="${A[1]}" var3="${A[3]}" var3="${A[3]}" var5="${A[5]}" var6="${A[6]}" ;; 
            esac 


            # see if we should try asd truncate the file
            ((fallocate_check_nlines++))
            (( fallocate_check_nlines >= fallocate_check_nlines0 )) && {
                # reset line counter
                fallocate_check_nlines=0
                
                # get read fd byte offset from procfs
                read -r </proc/self/fdinfo/$fdr
                byte_pos_cur="${REPLY#*$'\t'}"

                # remove data from the start of the file in 4096 byte blocks, up to but not past curren read fd byte offset
                (( ( byte_pos_cur - byte_pos_last ) > 4096 )) && {
                    bytes_rm="$(( 4096 * ( byte_pos_cur / 4096 ) - byte_pos_last ))"
                    fallocate -p -o ${byte_pos_cur} -l "$bytes_rm" "${tdir}"/data && byte_pos_last+="$bytes_rm"
                }
            }
        done

        # kill inotifywait
        kill -9 "$pid_inotify"
    ) {fd}<${tdir}/data {fd_wait0}<><(:) {fd_wait}<><(:)

    # rm tmp dir
    \rm -r $tdir
}  

printf '\n-------------------------------\n'

for nLines in {1..10} {12..20..2} {24..40..4}; do
echo "reading $nLines lines at a time (mapfile)"
( 
    for nn in {100000000..100000500}; do 
        linetype=$(( $RANDOM % 2 ));  
        case $linetype in 
            0) printf '%s a%s b%s c%s d%s\n' $linetype $nn $nn $nn $nn ;; 
            1) printf '%s z%s y%s x%s w%s v%s u%s t%s s%s r%s q%s p%s\n' $linetype $nn $nn $nn $nn $nn $nn $nn $nn $nn $nn $nn ;; 
        esac; 
        read -r -u $fdwait -t 0.01; 
    done; 
) {fdwait}<><(:) | ( 
    time { 
        while true; do
            mapfile -t -u $fd -n $nLines A; 
            [[ ${#A[@]} == 0 ]] && break; 
            for kk in "${!A[@]}"; do 
                case "${A[$kk]:0:1}" in 
                    0) read -r dummy var1 dummy var2 dummy <<<"${A[$kk]}" ;;
                    1) read -r dummy var1 dummy var2 dummy var3 dummy var4 dummy var5 dummy var6 <<<"${A[$kk]}" ;; 
                esac; 
            done; 
        done;
    }  
) {fd}<&0

printf '\n-------------------------------\n'
done


for nBytes in {100..1000..50}; do
    
echo "reading $nBytes bytes at a time (read -N)"
( 
    for nn in {100000000..100000500}; do 
        linetype=$(( $RANDOM % 2 ));  
        case $linetype in 
            0) printf '%s a%s b%s c%s d%s\n' $linetype $nn $nn $nn $nn ;; 
            1) printf '%s z%s y%s x%s w%s v%s u%s t%s s%s r%s q%s p%s\n' $linetype $nn $nn $nn $nn $nn $nn $nn $nn $nn $nn $nn ;; 
        esac; 
        read -r -u $fdwait -t 0.01; 
    done; 
) {fdwait}<><(:) | ( 
    time { 
        while true; do
            read -r -N $nBytes -u $fd x || break
            read -r -u $fd y 
            {
                while true; do
                    read -r -d ' ' || break
                    case "${REPLY}" in 
                        0) read -r var1 dummy var2 dummy ;;
                        1) read -r var1 dummy var2 dummy var3 dummy var4 dummy var5 dummy var6<<<"${A[$kk]}" ;; 
                    esac; 
                done;
            } <<<"${x}${y}"
        done;
    }  
) {fd}<&0

printf '\n-------------------------------\n'
done

)

read_speedtest

# RESULTS

:<<'EOF'

BASE CASE: reading in variables directly from pipe

real    0m5.108s
user    0m0.114s
sys     0m0.068s

-------------------------------
BASE CASE (alt): reading in variables directly from pipe to an array

real    0m5.106s
user    0m0.111s
sys     0m0.061s

-------------------------------
reading using a tmpfile (forkruns method - requires inotifywait and fallocate)

real    0m5.119s
user    0m0.162s
sys     0m0.041s

-------------------------------
reading 1 lines at a time (mapfile)

real    0m5.104s
user    0m0.179s
sys     0m0.124s

-------------------------------
reading 2 lines at a time (mapfile)

real    0m5.106s
user    0m0.176s
sys     0m0.125s

-------------------------------
reading 3 lines at a time (mapfile)

real    0m5.106s
user    0m0.189s
sys     0m0.111s

-------------------------------
reading 4 lines at a time (mapfile)

real    0m5.107s
user    0m0.166s
sys     0m0.130s

-------------------------------
reading 5 lines at a time (mapfile)

real    0m5.106s
user    0m0.171s
sys     0m0.117s

-------------------------------
reading 6 lines at a time (mapfile)

real    0m5.108s
user    0m0.185s
sys     0m0.114s

-------------------------------
reading 7 lines at a time (mapfile)

real    0m5.107s
user    0m0.161s
sys     0m0.128s

-------------------------------
reading 8 lines at a time (mapfile)

real    0m5.109s
user    0m0.155s
sys     0m0.139s

-------------------------------
reading 9 lines at a time (mapfile)

real    0m5.109s
user    0m0.171s
sys     0m0.119s

-------------------------------
reading 10 lines at a time (mapfile)

real    0m5.105s
user    0m0.173s
sys     0m0.111s

-------------------------------
reading 12 lines at a time (mapfile)

real    0m5.110s
user    0m0.146s
sys     0m0.135s

-------------------------------
reading 14 lines at a time (mapfile)

real    0m5.107s
user    0m0.140s
sys     0m0.134s

-------------------------------
reading 16 lines at a time (mapfile)

real    0m5.108s
user    0m0.159s
sys     0m0.119s

-------------------------------
reading 18 lines at a time (mapfile)

real    0m5.109s
user    0m0.142s
sys     0m0.127s

-------------------------------
reading 20 lines at a time (mapfile)

real    0m5.106s
user    0m0.150s
sys     0m0.115s

-------------------------------
reading 24 lines at a time (mapfile)

real    0m5.113s
user    0m0.149s
sys     0m0.111s

-------------------------------
reading 28 lines at a time (mapfile)

real    0m5.113s
user    0m0.143s
sys     0m0.114s

-------------------------------
reading 32 lines at a time (mapfile)

real    0m5.113s
user    0m0.149s
sys     0m0.095s

-------------------------------
reading 36 lines at a time (mapfile)

real    0m5.115s
user    0m0.122s
sys     0m0.112s

-------------------------------
reading 40 lines at a time (mapfile)

real    0m5.111s
user    0m0.114s
sys     0m0.113s

-------------------------------
reading 100 bytes at a time (read -N)

real    0m5.105s
user    0m0.198s
sys     0m0.093s

-------------------------------
reading 150 bytes at a time (read -N)

real    0m5.106s
user    0m0.226s
sys     0m0.086s

-------------------------------
reading 200 bytes at a time (read -N)

real    0m5.105s
user    0m0.211s
sys     0m0.086s

-------------------------------
reading 250 bytes at a time (read -N)

real    0m5.105s
user    0m0.202s
sys     0m0.082s

-------------------------------
reading 300 bytes at a time (read -N)

real    0m5.107s
user    0m0.201s
sys     0m0.089s

-------------------------------
reading 350 bytes at a time (read -N)

real    0m5.107s
user    0m0.197s
sys     0m0.082s

-------------------------------
reading 400 bytes at a time (read -N)

real    0m5.105s
user    0m0.197s
sys     0m0.077s

-------------------------------
reading 450 bytes at a time (read -N)

real    0m5.106s
user    0m0.210s
sys     0m0.076s

-------------------------------
reading 500 bytes at a time (read -N)

real    0m5.106s
user    0m0.198s
sys     0m0.073s

-------------------------------
reading 550 bytes at a time (read -N)

real    0m5.105s
user    0m0.191s
sys     0m0.071s

-------------------------------
reading 600 bytes at a time (read -N)

real    0m5.107s
user    0m0.171s
sys     0m0.092s

-------------------------------
reading 650 bytes at a time (read -N)

real    0m5.107s
user    0m0.174s
sys     0m0.082s

-------------------------------
reading 700 bytes at a time (read -N)

real    0m5.107s
user    0m0.196s
sys     0m0.072s

-------------------------------
reading 750 bytes at a time (read -N)

real    0m5.106s
user    0m0.179s
sys     0m0.074s

-------------------------------
reading 800 bytes at a time (read -N)

real    0m5.107s
user    0m0.191s
sys     0m0.066s

-------------------------------
reading 850 bytes at a time (read -N)

real    0m5.107s
user    0m0.187s
sys     0m0.075s

-------------------------------
reading 900 bytes at a time (read -N)

real    0m5.105s
user    0m0.183s
sys     0m0.064s

-------------------------------
reading 950 bytes at a time (read -N)

real    0m5.105s
user    0m0.168s
sys     0m0.072s

-------------------------------
reading 1000 bytes at a time (read -N)

real    0m5.107s
user    0m0.187s
sys     0m0.055s

-------------------------------
EOF
