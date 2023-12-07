runMemtesterPar() {
## launches $(nproc) parallel memtester instances 
#
# (optional) input is the number of iterations. 
# If no input: it will run until you stop it (e.g. with <ctrl> + c)
#
# memory used per memtester instance is: (memTotal - unevictable - 1 GB) / nprocs
#
# Each memtester instance will print its stdout to a unique log file at ./memtester/memtester.${ID}.log
# Each instance will also send both its stdout and stderr to the stdout/stderr of the shell that forked them all.

(
	declare -a P;
	mkdir -p ./memtester

	# figure out how much memory to use (in mb)
	memUse="$(( ( ( ( $(grep 'MemTotal' </proc/meminfo | sed -E s/'^.*\:[ \t]*([0-9]+) .*$'/'\1'/) ) - $(grep 'Unevictable' </proc/meminfo | sed -E s/'^.*\:[ \t]*([0-9]+) .*$'/'\1'/) ) - ( 2 ** 20 ) ) / ( 1024 * $(nproc) ) ))m"

	# launch memtester instances
	for kk in $(source /proc/self/fd/0 <<<"echo {1..$(nproc)}"); do
		{ source /proc/self/fd/0; }<<EOF
{ coproc p${kk} {
memtester ${memUse} ${1} | tee -a >(cat >./memtester/memtester.${kk}.log)
} 1>&\${fd1} 2>&\${fd2} 
} 2>/dev/null
P+=($p${kk}_PID)
EOF
	done;

	wait "${P[@]}"
	                                     
	) {fd1}>&1 {fd2}>&2
}