#!/bin/bash

# NOTE: the output in this example is not quite right. Something isnt being accounted for correctly with subshells. 
# But the overall format is correct, EXCEPT that all the forked `echo _d` commands should be split off into their own profiles.

# . <(curl https://raw.githubusercontent.com/jkool702/misc-public-scripts/refs/heads/timep_testing_7/timep.bash)

gg() (
    . <(for nn in {1..4};
do
    cat <<EOF
ff${nn}() {
echo ${nn}a
{ echo ${nn}b; }
( echo ${nn}c )
echo ${nn}d &
}
EOF

done);
    echo 0a;
    {
        echo 0b
    };
    ( echo 0c );
    echo 0d & ff1;
    {
        ff2
    };
    ( ff3 );
    ( ff4 & )
)

timep gg

##########################################################################################
# OUTPUT
: << 'EOF'
The function being time profiled has finished running!
timep will now process the logged timing data.
timep will save the time profiles it generates in "/dev/shm/.timep.13424C2E"

The following time profile is separated by context level (process ID (pid) + subshell and function nesting level + FUNCNAME)
For each line/command run in each pid, the total combined time from all evaluations (as well as the number of evaluations) is shown

FORMAT:
----------------------------------------------------------------------------
LINENO:  TOTAL_RUNTIME <<--- (COUNTx) { CMD }
----------------------------------------------------------------------------

NESTING LVL:    2
PID:            7493
NAME:           timep_runFunc
TIME:           0.166556 sec
ID:             7493.2 {timep_runFunc}

[ 7493.2 {timep_runFunc} ]  116:  0.166556 sec   <<--- (2x) { gg }

----------------------------------------------------------------

NESTING LVL:    3
PID:            7493
NAME:           gg
TIME:           0.287914 sec
ID:             7493.3 {gg}


[ 7493.3 {gg} ]  45:  0.167524 sec       <<--- (2x) { gg }
[ 7493->7497->7499.3 {gg} ]  56:  0.000312 sec   <<--- (4x) { for nn in {1..4} }
[ 7493->7497.3 {gg} ]  56:  0.037369 sec         <<--- (2x) { . <(for nn in {1..4};$'\n'do$'\n'    cat <<EOF$'\n'ff${nn}() {$'\n'echo ${nn}a$'\n'{ echo ${nn}b; }$'\n'( echo ${nn}c )$'\n'echo ${nn}d &$'\n'}$'\n'EOF$'\n'$'\n'done) }
[ 7493->7497->7499.3 {gg} ]  57:  0.008975 sec   <<--- (3x) { cat <<EOF$'\n'ff${nn}() {$'\n'echo ${nn}a$'\n'{ echo ${nn}b; }$'\n'( echo ${nn}c )$'\n'echo ${nn}d &$'\n'}$'\n'EOF$'\n' }
[ 7493->7497.3 {gg} ]  57:  0.000162 sec         <<--- (1x) { echo 0a }
[ 7493->7497.3 {gg} ]  59:  0.010379 sec         <<--- (2x) { echo 0b }
[ 7493->7497.3 {gg} ]  62:  0.000974 sec         <<--- (1x) { echo 0d }
[ 7493->7497.3 {gg} ]  62:  0.010584 sec         <<--- (2x) { ff1 }
[ 7493->7497.3 {gg} ]  64:  0.050453 sec         <<--- (3x) { ff2 }
[ 7493->7497->7514.3 {gg} ]  66:  0.000117 sec   <<--- (1x) { ff3 }
[ 7493->7497.3 {gg} ]  67:  0.001065 sec         <<--- (1x) { ff4 }

----------------------------------------------------------------

NESTING LVL:    3
PID:            7519
NAME:           gg
TIME:           0.001381 sec
ID:             7519.3 {gg}

[ 7493->7497.3 {gg} ]  67:  0.001381 sec         <<--- (1x) { ff4 }

----------------------------------------------------------------

NESTING LVL:    4
PID:            7493
NAME:           ff1
TIME:           0.011799 sec
ID:             7493.4 {ff1}


[ 7493->7497.4 {ff1} ]  45:  0.000080 sec        <<--- (1x) { ff1 }
[ 7493->7497.4 {ff1} ]  46:  0.000117 sec        <<--- (1x) { echo 1a }
[ 7493->7497.4 {ff1} ]  47:  0.010430 sec        <<--- (2x) { echo 1b }
[ 7493->7497.4 {ff1} ]  49:  0.001172 sec        <<--- (1x) { echo 1d }

----------------------------------------------------------------

NESTING LVL:    4
PID:            7493
NAME:           ff2
TIME:           0.042364 sec
ID:             7493.4 {ff2}


[ 7493->7497.4 {ff2} ]  40:  0.000126 sec        <<--- (1x) { echo 2a }
[ 7493->7497.4 {ff2} ]  41:  0.010459 sec        <<--- (2x) { echo 2b }
[ 7493->7497.4 {ff2} ]  43:  0.031701 sec        <<--- (2x) { echo 2d }
[ 7493->7497.4 {ff2} ]  45:  0.000078 sec        <<--- (1x) { ff2 }

----------------------------------------------------------------

NESTING LVL:    4
PID:            7493
NAME:           ff3
TIME:           0.010713 sec
ID:             7493.4 {ff3}


[ 7493->7497->7514.4 {ff3} ]  34:  0.000127 sec          <<--- (1x) { echo 3a }
[ 7493->7497->7514.4 {ff3} ]  35:  0.010519 sec          <<--- (2x) { echo 3b }
[ 7493->7497->7514.4 {ff3} ]  45:  0.000067 sec          <<--- (1x) { ff3 }

----------------------------------------------------------------

NESTING LVL:    4
PID:            7519
NAME:           ff4
TIME:           0.010689 sec
ID:             7519.4 {ff4}


[ 7519.4 {ff4} ]  28:  0.000129 sec      <<--- (1x) { echo 4a }
[ 7519.4 {ff4} ]  29:  0.010474 sec      <<--- (2x) { echo 4b }
[ 7519.4 {ff4} ]  45:  0.000086 sec      <<--- (1x) { ff4 }

----------------------------------------------------------------



Additional time profiles, including non-combined ones that show individual command runtimes, can be found under:
    /dev/shm/.timep.13424C2E
EOF
