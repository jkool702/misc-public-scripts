#!/usr/bin/env bash

declare -x MEMTESTER_TMPDIR

memtester_p() {
## runs several instances of "memtester" for you in parallel
# after calling memtester_p, check on the status/progress of all forked memtester instances by running `memtester_p -s`
#
# USAGE: memtester_p ( [-p <% total_mem>] || [-b <# bytes>] ) [-t <path>] [-n <# instances>] [-l <# loops>] [-q]
#        memtester_p -s [-t <path>]
#
# FLAGS: all flags are optional and have fairly reasonable defaults
#
#   -p <#> : Defines what percent of the total system memory memtester should use (between ALL instances).
#            <#> must be an integer between 1-99. Default is 80. Be careful if setting this higher than 90.
#
#   -b <#> : Defines the number of bytes to tell EACH memtester instance to use, in bytes. Total memory used will be N times this much.
#            IF this flag is given it will override any `-p` flags that were also passed. Default is to use `-p 80`, not `-b <bytes>`.
#
# -t <path>: Defines what directory to use as the tmpdir for logging the memtester output. 
#            Default is to create a new tmpdir (via mktemp)at /tmp/.memtester.XXXXXXXXX
#
#   -n <#> : Defines how many memtester instances to start (N). <#> must be a positive integer. Default is $(nprocs).
#
#   -l <#> : Defines how many memtester loops to run. <#> must be a non-negative integer. 0 means run indefinately. Default is 3.
#
#   -q     : Enables quiet mode. Typically the combined output from all memtester instances is sent to the terminals stderr. 
#            This supresses this output. Status can still be determined by looking at the log files or by running `getMemtesterStats`.
#
#   -s     : Call `getMemtesterStats` and exit. No memtester instances will be forked if a `-s` flag is present, regardless of any other inputs.
#            Note: you can check of the status of memtester instances forked from another terminal using `memtester_p -s -t <tmpdir_path>`
#
# NOTE: Any inputs not specified above will be silently dropped. Any invalid options will also be silently dropped and defaults will be used.
#
# DEPENDENCIES: memtester, sed, grep, tee, nproc, mktemp, mkdir, tail, sleep

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# make vars local

local -i memPrct memBytes memTotal nProcs nLoops kk
local quietFlag getStatsFlag newTmpDirFlag nn ff
local -gx MEMTESTER_TMPDIR

# figure out if we are just printing stats

{ [[ "${*}" == '-s' ]] || [[ "${*}" == '-s '* ]] || [[ "${*}" == *' -s' ]] || [[ "${*}" == *' -s '* ]]; } && getStatsFlag=true || getStatsFlag=false

# set defaults

memPrct=80
nLoops=3
quietFlag=false
if ${getStatsFlag}; then
    newTmpDirFlag=false
else
    newTmpDirFlag=true
    MEMTESTER_TMPDIR=''
fi

# parse inputs for user-specified options to override defaults

while (( $# > 0 )); do
    case "${1}" in
        '-p')  
            (( ${2} > 0 )) && (( ${2} < 100 )) && memPrct=${2}
            shift 2
        ;;
        '-b')
            (( ${2} > 0 )) && memBytes=${2}
            shift 2
        ;;
        '-t')
            MEMTESTER_TMPDIR="${2}"
            newTmpDirFlag=true
            shift 2
        ;;
        '-n')
            (( ${2} > 0 )) && nProcs=${2}
            shift 2
        ;;
        '-l')
            (( ${2} >= 0 )) && nLoops=${2}
            shift 2
        ;;
         '-q')
            quietFlag=true
            shift 1
        ;;
           '-s')
            shift 1
        ;;
    esac
done

# setup tmpdir

[[ ${MEMTESTER_TMPDIR} ]] || ${getStatsFlag} || {
    MEMTESTER_TMPDIR="/tmp/$(mktemp -u -d .memtester.XXXXXXXXX)"
    newTmpDirFlag=true
}
MEMTESTER_TMPDIR="${MEMTESTER_TMPDIR%/}"
${newTmpDirFlag} && mkdir -p "${MEMTESTER_TMPDIR}"

# define function "getMemtesterStats" to check status/progress of all memtester instances

{ ${newTmpDirFlag} || ! declare -F getMemtesterStats &>/dev/null; } && {
source /proc/self/fd/0 <<EOF
export -nf getMemtesterStats &>/dev/null
getMemtesterStats() (
    local tailOffset lineResultsCur nn ff
    local -Igx MEMTESTER_TMPDIR

    until grep -qE '^Loop' "${MEMTESTER_TMPDIR}"/memtester.log.1; do
        sleep 1
    done

    tailOffset=\$(grep -m 1 -n -E '^Loop' "${MEMTESTER_TMPDIR}"/memtester.log.1 | sed -E s/':.*$'//)

    for ff in "${MEMTESTER_TMPDIR}"/memtester.log.*; do
        echo "\$(sed -E s/':.*ok$'/': ok'/ "\${ff}")" > "\${ff}"
    done

    tail -n +\${tailOffset} <"${MEMTESTER_TMPDIR}"/memtester.log.1 | grep -F ':' | sed -E s/':.*$'// | while read -r nn; do 

    printf -v lineResultsCur '%s ' \$(for ff in "${MEMTESTER_TMPDIR}"/memtester.log.*; do tail -n +\${tailOffset} <"\${ff}" | head -n 19 | grep -m 1 "\$nn"; done | sed -E 's/^.*://; s/memtester version.*$//; s/^.*([^[:alnum:]]+)([[:alnum:]]+)$/ \2/; s/^[ \t]*(Loop [0-9]+) .*$/\n\1/'); 
    
    ((tailOffset++))

    if grep -qE '^[0-9 ok\-\\\|\/]+$' <<<"\${lineResultsCur}"; then
        printf '        %s %s \n' "\${nn}" "\${lineResultsCur}"
    else
        printf 'ERROR:  %s %s\ <<======= \n' "\${nn}" "\${lineResultsCur}"
    fi
    done | sed -E 's/^.*Loop/Loop/; s/Stuck Address /Stuck Address        /; s/Random Value /Random Value         /; s/Compare XOR /Compare XOR          /; s/Compare SUB /Compare SUB          /; s/Compare MUL /Compare MUL          /; s/Compare DIV /Compare DIV          /; s/Compare OR /Compare OR           /; s/Compare AND /Compare AND          /; s/Sequential Increment /Sequential Increment /; s/Solid Bits /Solid Bits           /; s/Block Sequential /Block Sequential     /; s/Checkerboard /Checkerboard         /; s/Bit Spread /Bit Spread           /; s/Bit Flip /Bit Flip             /; s/Walking Ones /Walking Ones         /; s/Walking Zeroes /Walking Zeroes       /; s/8-bit Writes /8-bit Writes         /; s/16-bit Writes/16-bit Writes       /'
)
export -f getMemtesterStats
EOF
}

# if printing stats call getMemtesterStats and return

${getStatsFlag} && {
    [[ ${MEMTESTER_TMPDIR} ]] && getMemtesterStats || printf '\nERROR - memtester tmp dir is unknown.\nPlease specify via "memtester_p -s -t $path"\n'
    return
}

# figure out how many instances and how much memory each memtester instance should use

[[ ${nProcs} ]] || nProcs=$(nproc)
memTotal=$(grep 'MemTotal' </proc/meminfo | sed -E s/'^.*\:[ \t]*([0-9]+) .*$'/'\1'/)
[[ ${memBytes} ]] || memBytes="$(( ( ( ( ${memTotal} - $(grep 'Unevictable' </proc/meminfo | sed -E s/'^.*\:[ \t]*([0-9]+) .*$'/'\1'/) ) - ( 2 ** 20 ) ) * 10 * ${memPrct} ) / ( ${nProcs} ) ))"

# memory sanity check

if (( ( nProcs * memBytes ) > ( 1000 * memTotal ) )); then
    printf '\nWARNING: in total, memtester will use %s KB of memory. \nThis is more than the total amount of system RAM!!\n\nType "YES" if you want to continue?    ' "$(( nProcs * memBytes ))" >&2
    read -r
    [[ "${REPLY}" == 'YES' ]] || return
fi

# fork ${nProcs} memtester instances

if ${quietFlag}; then
    for (( kk=1; kk<=${nProcs}; kk++ )); do           
        {
            memtester ${memBytes}B ${nLoops} | tee -a "${MEMTESTER_TMPDIR}"/memtester.log.$kk >/dev/null
        } &
    done 
else
    for (( kk=1; kk<=${nProcs}; kk++ )); do           
        {
            memtester ${memBytes}B ${nLoops} | tee -a "${MEMTESTER_TMPDIR}"/memtester.log.$kk >&${fd}
        } &
    done {fd}>&2
fi

}
