#!/usr/bin/env bash

read_speedtest() (

echo "BASE CASE: reading direct from pipe"
( 
    for nn in {100000000000..100000000100}; do 
        linetype=$(( $RANDOM % 2 ));  
        case $linetype in 
            0) printf '%s a%s b%s c%s d%s\n' $linetype $nn $nn $nn $nn ;; 
            1) printf '%s z%s y%s x%s w%s v%s u%s t%s\n' $linetype $nn $nn $nn $nn $nn $nn $nn ;; 
        esac; 
        read -r -u $fdwait -t 0.02; 
    done; 
) {fdwait}<><(:) | ( 
    time { 
        while true; do
            read -r -d ' ' -u "$fd" || break
            case "${REPLY}" in 
                0) read -r -u "$fd" var1 dummy var2 dummy ;;
                1) read -r -u "$fd" var1 dummy var2 dummy var3 dummy var4 <<<"${A[$kk]}" ;; 
            esac; 
        done;
    }  
) {fd}<&0

printf '\n-------------------------------\n'


for nLines in {1..10} {12..20..2} {24..40..4}; do
echo "reading $nLines lines at a time (mapfile)"
( 
    for nn in {100000000000..100000000100}; do 
        linetype=$(( $RANDOM % 2 ));  
        case $linetype in 
            0) printf '%s a%s b%s c%s d%s\n' $linetype $nn $nn $nn $nn ;; 
            1) printf '%s z%s y%s x%s w%s v%s u%s t%s\n' $linetype $nn $nn $nn $nn $nn $nn $nn ;; 
        esac; 
        read -r -u $fdwait -t 0.02; 
    done; 
) {fdwait}<><(:) | ( 
    time { 
        while true; do
            mapfile -t -u $fd -n $nLines A; 
            [[ ${#A[@]} == 0 ]] && break; 
            for kk in "${!A[@]}"; do 
                case "${A[$kk]:0:1}" in 
                    0) read -r dummy var1 dummy var2 dummy <<<"${A[$kk]}" ;;
                    1) read -r dummy var1 dummy var2 dummy var3 dummy var4 <<<"${A[$kk]}" ;; 
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
    for nn in {100000000000..100000000100}; do 
        linetype=$(( $RANDOM % 2 ));  
        case $linetype in 
            0) printf '%s a%s b%s c%s d%s\n' $linetype $nn $nn $nn $nn ;; 
            1) printf '%s z%s y%s x%s w%s v%s u%s t%s\n' $linetype $nn $nn $nn $nn $nn $nn $nn ;; 
        esac; 
        read -r -u $fdwait -t 0.02; 
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
                        1) read -r var1 dummy var2 dummy var3 dummy var4 <<<"${A[$kk]}" ;; 
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
