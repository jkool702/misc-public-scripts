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
