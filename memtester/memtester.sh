#!/usr/bin/env bash

runMemtester() {
## launches $(nproc) parallel memtester instances 
#
# (optional) input is the number of iterations. 
# If no input: it will run until you stop it (e.g. with <ctrl> + c)
#
# memory used per memtester instance is: (memTotal - unevictable - 1 GB) / nprocs
#
# Each memtester instance will print its stdout/stderr to a unique log file at ./memtester/memtester.${ID}.std[out|err]log
# Each instance will also send both its stdout and stderr to the stdout/stderr of the shell that forked them all.

(
	local -a P
	local -i iter memUse kk
	mkdir -p ./memtester

	iter=$1

	# figure out how much memory to use (in mb)
	memUse="$(( ( ( ( $(grep 'MemTotal' </proc/meminfo | sed -E s/'^.*\:[ \t]*([0-9]+) .*$'/'\1'/) ) - $(grep 'Unevictable' </proc/meminfo | sed -E s/'^.*\:[ \t]*([0-9]+) .*$'/'\1'/) ) - ( 2 ** 20 ) ) / ( 1024 * $(nproc) ) ))m"

	# launch memtester instances
	for (( kk=1; kk<=$(nproc); kk++ )) do

{ source /proc/self/fd/0; }<<<"{
coproc p${kk} {
    memtester ${memUse} ${iter} 2>(tee >(cat >./memtester.${kk}.stderr.log) >&\${fd02}) | tee -a >(cat >./memtester/memtester.${kk}.stdout.log) >&\${fd1}
  } {fd01}>&\${fd1} {fd02}>&\${fd2}
} 2>/dev/null
P+=(\${p${kk}_PID})"

	done

    # wait until they finish / are killed
	wait "${P[@]}"
	                                     
	) {fd1}>&1 {fd2}>&2
}