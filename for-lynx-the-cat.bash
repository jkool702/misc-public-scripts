#!/bin/bash

npings=300

time {


	# create tmpdir
	tdir=$(mktemp -d -p /dev/shm); : > ${tdir}/data
	(
		LC_ALL=C
		LANG=C

		declare -i fallocate_check_nlines fallocate_check_nlines0 byte_pos_cur byte_pos_last bytes_rm

		# attempt to truncate file(in 4096-byte blocks) every time this many lines are read
		fallocate_check_nlines0=1000
		
		# fork inotifywait to wattch tmpfile
		inotifywait -m -e modify --format='\n' >&"$fd_wait" "${tdir}"/data 2>/dev/null &
		pid_inotify="${!}"

		# fork 4x ping processes, each pings 10 times a second and writes output to file
		{ ping -A -c "$npings" -i 0.1 1.1.1.1 >&"$fdw"; touch "${tdir}"/done1; echo >&"$fdw"; } &
		{ ping -A -c "$npings" -i 0.1 1.0.0.1 >&"$fdw"; touch "${tdir}"/done2; echo >&"$fdw"; } &
		{ ping -A -c "$npings" -i 0.1 www.google.com >&"$fdw"; touch "${tdir}"/done3; echo >&"$fdw"; } &
		{ ping -A -c "$npings" -i 0.1 8.8.8.8 >&"$fdw"; touch "${tdir}"/done4; echo >&"$fdw"; } &
		{ ping -A -c "$npings" -i 0.1 gstatic.com >&"$fdw"; touch "${tdir}"/done5; echo >&"$fdw"; } &

		# loop until processes are finished
		stopFlag=false
		until $stopFlag; do

			# OPTIONAL - brief wait to let input accumulate (not used)
			# reads data in larger chunks --> more efficient, but increases latency
#			#read -r -u "$fd_wait0" -t 0.2

			# wait for inotifywait to tell you there is data
			read -r -u "$fd_wait"

			# read all the data you can. NOTE: no -t flag keeps the delimiter. Wont work with NULL delimiter.
			mapfile -u "$fdr" A

			# make sure you stopped reading data on a line break
			[[ "${#A[@]}" == 0 ]] || [[ "${A[-1]: -1}" == $'\n' ]] || { read -r -u "$fdr"; A[-1]="${A[-1]}${REPLY}"$'\n'; }

			# DO SOMETHING - vectorized version (not used)
#			#printf '%s\n' "${A[@]%$'\n'}"

			# DO SOMETHING - non-vectorized version		
			for nn in "${A[@]%$'\n'}"; do
				echo "$nn"
			done

			# end condition
			[[ -f "${tdir}"/done1 ]] && [[ -f "${tdir}"/done2 ]] && [[ -f "${tdir}"/done3 ]] && [[ -f "${tdir}"/done4 ]] && [[ -f "${tdir}"/done5 ]] && stopFlag=true

			# see if we should try asd truncate the file
			fallocate_check_nlines+="${#A[@]}"
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
	) {fdw}>${tdir}/data {fdr}<${tdir}/data {fd_wait0}<><(:) {fd_wait}<><(:)

	# rm tmp dir
	\rm -r $tdir
} >/dev/null

time {
	tdir=$(mktemp -d -p /dev/shm);                                 
	(


		# fork 5x ping processes, each pings 10 times a second and writes output to pipe

		{ ping -A -c $npings -i 0.1 1.1.1.1 >&$fd; touch "${tdir}"/done1; echo >&$fd; } &             
		{ ping -A -c $npings -i 0.1 1.0.0.1 >&$fd; touch "${tdir}"/done2; echo >&$fd; } &             
		{ ping -A -c $npings -i 0.1 www.google.com >&$fd; touch "${tdir}"/done3; echo >&$fd; } &             
		{ ping -A -c $npings -i 0.1 8.8.8.8 >&$fd; touch "${tdir}"/done4; echo >&$fd; } &
		{ ping -A -c $npings -i 0.1 gstatic.com >&$fd; touch "${tdir}"/done5; echo >&$fd; } &

	    # loop until processes are finished
	    until { [[ -f ${tdir}/done1 ]] && [[ -f ${tdir}/done2 ]] && [[ -f ${tdir}/done3 ]] && [[ -f ${tdir}/done4 ]] && [[ -f ${tdir}/done5 ]] && [[ -z $A ]]; }; do        
	    	
	    	# read data directly from pipe
	    	read -r -u $fd A

	    	# DO SOMETHING                                                  
			echo "$A"                                                                                

		done                      
	) {fd}<><(:)
} >/dev/null

## ROUGH APPEMPT WITH NO FALLOCATE

#!/bin/bash

npings=300

time {


    # create tmpdir
    tdir=$(mktemp -d -p /dev/shm); : > ${tdir}/data
    (
        LC_ALL=C
        LANG=C

        declare -i check_nlines check_nlines0 byte_pos_cur byte_pos_last bytes_rm

        # attempt to truncate file(in 4096-byte blocks) every time this many lines are read
        check_nlines0=1000
        
        # fork inotifywait to wattch tmpfile
        inotifywait -m -e modify,close_write --format='\n' >&"$fd_wait" "${tdir}"/data 2>/dev/null &
        pid_inotify="${!}"

        # fork 4x ping processes, each pings 10 times a second and writes output to file
        { ping -A -c "$npings" -i 0.1 1.1.1.1 >&"$fdw"; touch "${tdir}"/done1; echo >&"$fdw"; } &
        { ping -A -c "$npings" -i 0.1 1.0.0.1 >&"$fdw"; touch "${tdir}"/done2; echo >&"$fdw"; } &
        { ping -A -c "$npings" -i 0.1 www.google.com >&"$fdw"; touch "${tdir}"/done3; echo >&"$fdw"; } &
        { ping -A -c "$npings" -i 0.1 8.8.8.8 >&"$fdw"; touch "${tdir}"/done4; echo >&"$fdw"; } &
        { ping -A -c "$npings" -i 0.1 gstatic.com >&"$fdw"; touch "${tdir}"/done5; echo >&"$fdw"; } &

        # loop until processes are finished
        stopFlag=false
        until $stopFlag; do
            \rm -f  "${tdir}"/catDone
            ( trap 'touch "${tdir}"/catDone' EXIT; cat <&${fdw} >"${tdir}"/data; ) &
            catPID=$!
            check_nlines=0
            truncateFlag=false
            {
                until { ${truncateFlag} || ${stopFlag}; }; do
                
                    printf -v pDone '%.1s' "${tdir}"/done*
                                        
                    if [[ ${#pDone} == 5 ]]; then
                             stopFlag=true
                            [[ ${#A[@]} == 0 ]] && { kill $catPID;  break; }

                        
                        
                    else
      
                        read -r -u "$fd_wait" -t 0.1
                    
                        (( check_nlines >= check_nlines0 )) && {
                            truncateFlag=true
                            kill $catPID 2>/dev/null
                        }   
                    fi
                    
                    # read all the data you can. NOTE: no -t flag keeps the delimiter. Wont work with NULL delimiter.
                    mapfile -u "$fdr" A

                    # make sure you stopped reading data on a line break
                    [[ "${#A[@]}" == 0 ]] || {
                        { ${truncateFlag} && ${catDoneFlag}; } || ${stopFlag} || [[ "${A[-1]: -1}" == $'\n' ]] || { 
                            read -r -u "$fdr"; 
                            A[-1]="${A[-1]}${REPLY}"$'\n';
                        }
                        
                        # add to running line count total
                        check_nlines+="${#A[@]}"
                    

                        # DO SOMETHING - vectorized version (not used)
                        #printf '%s\n' "${A[@]%$'\n'}"

                        # DO SOMETHING - non-vectorized version        
                        for nn in "${A[@]%$'\n'}"; do
                            echo "$nn"
                        done
                    }

                    
                done 
            } {fdr}<"${tdir}"/data
            exec {fdr}<&-
            \rm "${tdir}"/data
        done

        # kill inotifywait
        kill -9 "$pid_inotify"

    # rm tmp dir
    \rm -r "$tdir"
    exit
    ) {fdw}<><(:) {fd_wait}<><(:)

} >/dev/null
