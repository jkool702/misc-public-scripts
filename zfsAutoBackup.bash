#!/usr/bin/env bash

zfsGetRoot() {
	# use flag '-p' or '--pool' to get the pool name containing the root dataset. Otherwise the root dataset name is returned
	[[ ${1,,} =~ ^-+p(ool)?$ ]] && zfs get mounted $(zfs get mountpoint -H | grep "$(echo -e "mountpoint\t\/\t")" | sed -E s/'^([^ \t]*)[ \t\/].*$'/'\1'/) -H | grep 'yes' | sed -E s/'^([^ \t\/]*)[ \t\/].*$'/'\1'/ || zfs get mounted "$(zfs get mountpoint -H | grep "$(echo -e "mountpoint\t\/\t")" | sed -E s/'^([^ \t]*)[ \t\/].*$'/'\1'/)" -H | grep 'yes' | sed -E s/'^([^ \t]*)[ \t].*$'/'\1'/
}

zfsSnapshotRoot() {
	zfs snapshot -r "$(zfsGetRoot -p)@$(date +%Y-%m-%d_%H:%M:%S)"
}

zfsDatasetExists() {
	[[ -n "$(zfs list "${1}" 2>/dev/null )" ]]
}

zfsGetNewestSnapshot() {
	local -a zfsDataset
	local -a zfsDataset0
	local rFlag
	local cFlag=0
	local nn
	local n0
	local n0new
	local n1
	local n1new
	local kk=0

	zfsDataset=("${@}")
	(( ${#zfsDataset[@]} == 0 )) && zfsDataset=("$(zfsGetRoot -p)")
	for kk in ${!zfsDataset[@]}; do
		[[ "${zfsDataset[$kk],,}" == '-r' ]] && rFlag='-r' && zfsDataset[$kk]=""
		[[ "${zfsDataset[$kk],,}" == '-c' ]] && cFlag=1 && zfsDataset[$kk]=""
		zfsDatasetExists "${zfsDataset[$kk]}" || zfsDataset[$kk]=""
	done
	zfsDataset=(${zfsDataset[@]})
	(( ${#zfsDataset[@]} == 0 )) && zfsDataset=("$(zfsGetRoot -p)")
	mapfile -t zfsDataset0 < <(zfs list -H ${rFlag} "${zfsDataset[@]}" -o name)
	for nn in "${zfsDataset0[@]}"; do 
		if (( ${cFlag} == 0 )); then
			zfs get name -H -r -o value "${nn}" | grep "${nn}@" | tail -n 1
		else
			n0new="$(zfs get name -H -r -o value "${nn}" | grep "${nn}@")"
			if [[ -n "${n0new}" ]]; then
				if [[ -z "${n0}" ]]; then
					n0="${n0new}"
					n1="$(echo "${n0}" | sed -E s/'^[^\@]+\@(.*)$'/'\1'/)"
				else
					n0="$(cat <(echo "${n0}") <(echo "${n0new}"))"
					n1new="$(echo "${n0new}" | sed -E s/'^[^\@]+\@(.*)$'/'\1'/)"			
					n1="$(diff <(echo "${n1}") <(diff <(echo "${n1}") <(echo "${n1new}") -d | grep '<' | sed -E s/'< '//) -d | grep '<' | sed -E s/'< '//)"
				fi
			fi
		fi
	done
	(( ${cFlag} == 0 )) && return 0
	[[ -z "${n1}" ]] && echo -e "\nNo common snapshots found\n" >&2 && ( [[ "${rFlag}" == '-r' ]] && echo -e "\nNOTE:\n\nWhen the recursion flag (-r) and \nthe common snapshot flag (-c) are \nboth used, the selected datasets \n----- AND ALL SUB-DATASETS -----\nmust ALL share a snapshot with the \nsame name to return a non-NULL value.\n" >&2 ) && return 1 

	#echo "${n0}" | grep "$(echo "${n1}" | tail -n 1)"
	printf '%s@'"$(echo "${n1}" | tail -n 1)"'\n' "${zfsDataset[@]}"
}

zfsGetOldestSnapshot() {

	local nn

	for nn in "${@}"; do
		zfs get name -H -r -o value "${nn}" | grep "${nn}@" | head -n 1
	done
}

zfsGetEncryptionRoot() {
	# use flag '-u' or '--unavailable' to only return encryption roots that have not had their keys loaded
	# use flag '-a' or '--available' to only return encryption roots that have already had their keys loaded
	
	local zfsEncryptionRoot	
	local uaFlag
	local rFlag

	[[ "${1,,}" =~ ^-+r(ecurs(e|(ive)|(ion)))?$ ]] && rFlag=-r && shift 1
	
	if [[ ${1,,} =~ ^-+u(navailable)?$ ]]; then
		uaFlag='unavailable'
		shift 1
	elif [[ ${1,,} =~ ^-+a(vailable)?$ ]]; then
		uaFlag='available'
		shift 1
	fi

	[[ "${1,,}" =~ ^-+r(ecurs(e|(ive)|(ion)))?$ ]] && rFlag=-r && shift 1

	zfsEncryptionRoot="$(zfs get encryptionroot -H -o value ${rFlag} "${@}" | grep -v '-' | sort -u)"

	if [[ -z ${zfsEncryptionRoot} ]]; then
		echo "No encryption roots found" >&2
	elif [[ -z "${uaFlag}" ]]; then
		echo "${zfsEncryptionRoot}" | sort -u
	else
		zfs get keystatus -H ${zfsEncryptionRoot} -o name,value | grep "$(echo -e "\t${uaFlag}")" | sed -E s/'^([^ \t]*)[ \t].*$'/'\1'/ | sort -u
	fi
	
	#zfs get keystatus -H -o value  | grep -q 'unavailable' && zfs get encryptionroot -H $(zfs get keystatus -Hr ${@} | grep unavailable | grep -v '@' | sed -E s/'^([^ \t]*)[ \t\/].*$'/'\1'/) | sed -E s/'^.*encryptionroot\t([^\t]*)\t.*$'/'\1'/ | sort -u

	#zfs get keystatus -H -o value ${@} | grep -q 'available' && zfs get encryptionroot -H $(zfs get keystatus -Hr ${@} | grep available | grep -v '@' | sed -E s/'^([^ \t]*)[ \t\/].*$'/'\1'/) | sed -E s/'^.*encryptionroot\t([^\t]*)\t.*$'/'\1'/ | sort -u

}

zfsClevisDecrypt() {
	local nn

	zfsGetEncryptionRoot -u -r "${@}" | while read -r nn; do 
		if zfsDatasetExists "${nn%/*}/KEYS"; then 
			clevis decrypt < <( ( [[ "$(/sbin/zfs get -H -o value mounted "${nn%/*}/KEYS")" == "yes" ]] || /sbin/zfs mount "${nn%/*}/KEYS" ) && cat "$(/sbin/zfs get -H -o value mountpoint "${nn%/*}/KEYS")/secret.jwe" && /sbin/zfs umount "${nn%/*}/KEYS" && sleep 1 ) | /sbin/zfs load-key 2>/dev/null "${nn}" && echo "'${nn}' dataset decrypted successfully using clevis-tpm2" >&2 || echo "Automatic decryption via clevis-tpm2 not available for the '${nn}' dataset" >&2 && zfs load-key "${nn}"
		fi	
	done
}

zfsTPMDecrypt() {
	local nn
	local hp
	local ht

	zfsGetEncryptionRoot -r -u "${@}" | while read -r nn; do
		/bin/tpm2_getcap handles-persistent | sed -E s/'^- '// | while read -r hp; do 
			echo "$(/bin/tpm2_unseal -c "${hp}" 2>/dev/null 2>/dev/null && [ $(/bin/tpm2_getcap handles-transient | wc -l) -gt 0 ] && /bin/tpm2_getcap handles-transient | sed -E s/'^- '// | while read -r ht; do bin/tpm2_flushcontext "${ht}"; done)" | /sbin/zfs load-key "${nn}" && echo "${nn} decrypted sucessfully using the system's TPM2 module" >&2 || echo "Automatic TPM2 decryption is NOT available for ${nn}" >&2	
		done
	done
}

zfsBackupRoot() {
	local zfsRoot
	local zfsBackupRoot
	local nn
	local -a nn0

	zfsRoot="$(zfsGetRoot -p)"
	[[ -n "${1}" ]] && [[ -n "$(zfs list "${1}" 2>/dev/null )" ]] && zfsBackupRoot="${1}" && shift 1 || zfsBackupRoot="DATA/FEDORA_BACKUP"

	#zfsClevisDecrypt "${zfsBackupRoot}"
	zfsTPMDecrypt "${zfsBackupRoot}"

	zfsSnapshotRoot
	sleep 1
	sync

	zfs list -H -r -o name "${zfsRoot}" | while read -r nn; do 
	#	nn0="$(zfsGetNewestSnapshot -c "${nn}" "${zfsBackupRoot}/${nn}" | grep "${zfsBackupRoot}/${nn}@")"
	#	zfs send -I "${nn0#${zfsBackupRoot}/}" "$(zfsGetNewestSnapshot "${nn}")" | zfs receive -F "${nn0%@*}" 
		mapfile -t nn0 < <(zfsGetNewestSnapshot -c "${nn}" "${zfsBackupRoot}/${nn}")
	
		if (( ${#nn0[@]} < 2 )); then
			zfs send "$(zfsGetOldestSnapshot "${nn}")" | zfs receive -F -d "${zfsBackupRoot}/${nn%%\/*}"
			sleep 1
			sync
			mapfile -t nn0 < <(zfsGetNewestSnapshot -c "${nn}" "${zfsBackupRoot}/${nn}")
		fi
		
		zfs send -I "${nn0[0]}" "$(zfsGetNewestSnapshot "${nn}")" | zfs receive -F "${nn0[1]%@*}"
	done

	return 0
}

zfsAutoRemoveSnapshots() {
	# Automatically removes old snapshots
	#
	# Syntax: zfsAutoRemoveSnapshots [-c{0,1h,3h,6h,12h,(24h|1d),(7d|1w),1m}=#] [-v] [-q] [-nr] [-dr] RootDatasetName
	#
	# If 'RootDatasetName' is not given all available datasets/snapshots will be considered. Multiple RootDatasetName's can be given.
	#
	# This program allows for the following different snapshot density levels: 
	# 	unrestricted, 1/hr (24/day), 1/3hr (8/day), 1/6hr (4/day), 1/12hr (2/day), 1/24hr (1/day), 1/week (1/7day), 1/month (1/4-5weeks), and 1/year (1/12months)
	#
	# Note: in order to retain alignment between the different snapshot density blocks, the "1/month" block begins at midnight on the 1st Monday of the month, and will last for either 4 or 5 weeks. Similarly, the "1/year" block begins at midnight on the 1st Monday of the year.
	#
	# Use flags '-c{0,1h,3h,6h,12h,(24h|1d),(7d|1w),1m}}=#' or '--cut[off]{0,1h,3h,6h,12h,(24h|1d),(7d|1w),1m}=#' 
	# 	to control how old snapshots must be to fall into the 5 different snapshot density categories
	#	'#' is interpreted as "# of days" by default, and following modifiers are recognized: '#d[ays]', '#w[eeks]', '#h[ours]'
	#
	# # # # # DEFAULT CUTOFFS
	#
	# 	cut0=1d   			# keep all snapshots for snapshots up to 1 days old 
	# 	cut1h=1w   			# keep 1 per hour block (up to 24/day) for snapshots between 2-7 days
	# 	cut3h=2w  			# keep 1 per 3 hour block (up to 8/day) for snapshots between 1-2 weeks old
	# 	cut6h=4w 			# keep 1 per 6 hour block (up to 4/day) for snapshots between 3-4 weeks old
	# 	cut12h=8w 			# keep 1 per 12 hour block (up to 2/day) for snapshots between 5-8 weeks old 
	# 	cut{24h,1d}=16w 	# keep daily snapshots between 9-16 weeks old 
	# 	cut{7d,1w}=52w 		# keep weekly snapshots between 17-52 weeks old 
	# 	cut{1m}=52w 		# keep monthly snapshots between 53-104 weeks (1-2 years) old 
	# 	--------------> 	# keep yearly for snapshots 104+ weeks (2+ years) old 
	#
	# Use flag '-e=STR' or '--exclude=STR' to exclude snapshots that include STR in the name (implemented via `grep -v STR`).
	# 	This flag can be given multiple times to provide multiple patterns to exclude
	# 	Note: the single oldest snapshot from each dataset is excluded by default
	#
	# Use flag '-v' or '--verbose' to increase verbosity level (i.e., print out more information)
	# Use flag '-q' or '--quiet' to decrease verbosity level (i.e., print out less information)
	# 	Note: the '-v' and '-q' flags may be specified multiple times, though increasing/decreasing the verbosity  
	# 	level by >2 levels has no additional effect. If both flags are specified they cancel each other out.
	#
	# Use flag '-dr' or '--dry-run' to print out the 'zfs destroy [...]' commands instead of running them 
	#
	# Use flag '-nr' or '--no-recursion' to only consider snapshots directly of the selected dataset(s)
	# NOTE: THE DEFAULT BEHAVIOR (WHEN THIS FLAG IS *NOT* GIVEN) IS TO CONSIDER SNAPSHOTS OF THE SELECTED DATASETS AND ALL CHILD DATASETS
	#
	# Note: flags must be given as individual inputs. i.e., use '-v -v -nr', not '-vvnr'. The order of the inputs/flags does not matter.

	# # # # # INITIAL FUNCTION PREP AND INPUT PARSING # # # # #

	# Define local variables

	local -a dset snap tSnap dtSec dtDay dtWeek dtMonth dtYear hSnap dtDayUniq dtWeekUniq dtMonthUniq dtYearUniq
	local tNow tNowDay tNowWeek curMonth curYear dtNowDayWeek rootName dsetName ageDays ageWeeks ageMonths ageYears kk kkCur0 kkCur0w kkCur0m kkCur0y kkCur1 kkCur1w kkCur1m kkCur1y hBlockStart dh cut0 cut1h cut3h cut6h cut12h cut1d cut1w cut1m ageWeekMin ageMonthMin ageYearMin excludeStr verboseLevel nrFlag drFlag tripFlag

	verboseLevel=2 
	nrFlag=0 
	drFlag=0 
	tripFlag=0


	# Define function to parse cutoffs ending with 'd', 'w'
	parseCutoffAge() (
		local nn
		for nn in "${@}"; do
			( [[ "${nn,,}" =~ ^[0-9]+[\ \-\_]?(d(ays?)?)?$ ]] && echo "${nn%%[Dd]*}" ) || ( [[ "${nn,,}" =~ ^[0-9]+[\ \-\_]?w(eeks?)?$ ]] && echo "$((( ${nn%%[Ww]*} * 7 )))" ) || ( [[ "${nn,,}" =~ ^[0-9]+[\ \-\_]?h(ours?)?$ ]] && echo "$((( ${nn%%[Hh]*} / 24 )))" ) || ( [[ "${nn}" =~ ^\-[0-9]+.*$ ]] && echo '0' ) || echo "Input not recognized as a valid age" >&2
		done
	)

	# Parse inputs
	while (( $# > 0 )); do
		if [[ "${1}" =~ ^\-+v(erbose)?$ ]]; then
			((verboseLevel++))
		elif [[ "${1}" =~ ^\-+q(uiet)?$ ]]; then
			((verboseLevel--))
		elif [[ "${1}" =~ ^\-+no?-?r(ecurs(e|(ion)|(ive)))?$ ]]; then
			nrFlag=1
		elif [[ "${1}" =~ ^\-+d(ry)?-?r(un)?$ ]]; then
			drFlag=1
		elif [[ "${1}" =~ ^\-+e(xclude)?=.+$ ]]; then
			excludeStr="${excludeStr} -e $(echo "${1##*=}" | sed -E s/'^"(.)"$'/'\1'/ | sed -E s/''"'"'(.*)'"'"''/'\1'/)"
		elif [[ "${1}" =~ ^\-+c(ut(off)?)?[\-\_]?0(h(ours?)?)?=\-?[0-9]+.*$ ]]; then
			cut0="$(parseCutoffAge "${1##*=}")"
		elif [[ "${1}" =~ ^\-+c(ut(off)?)?[\-\_]?1(h(ours?)?)?=\-?[0-9]+.*$ ]]; then
			cut1h="$(parseCutoffAge "${1##*=}")"
		elif [[ "${1}" =~ ^\-+c(ut(off)?)?[\-\_]?3(h(ours?)?)?=\-?[0-9]+.*$ ]]; then
			cut3h="$(parseCutoffAge "${1##*=}")"
		elif [[ "${1}" =~ ^\-+c(ut(off)?)?[\-\_]?6(h(ours?)?)?=\-?[0-9]+.*$ ]]; then
			cut6h="$(parseCutoffAge "${1##*=}")"
		elif [[ "${1}" =~ ^\-+c(ut(off)?)?[\-\_]?12(h(ours?)?)?=\-?[0-9]+.*$ ]]; then
			cut12h="$(parseCutoffAge "${1##*=}")"
		elif [[ "${1}" =~ ^\-+c(ut(off)?)?[\-\_]?((24(h(ours?)?)?)|(1d(ays?)?))=\-?[0-9]+.*$ ]]; then
			cut1d="$(parseCutoffAge "${1##*=}")"
		elif [[ "${1}" =~ ^\-+c(ut(off)?)?[\-\_]?((7d(ays?)?)|(1w(eeks?)?))=\-?[0-9]+.*$ ]]; then
			cut1w="$(parseCutoffAge "${1##*=}")"
		elif [[ "${1}" =~ ^\-+c(ut(off)?)?[\-\_]?1m(onths?)?=\-?[0-9]+.*$ ]]; then
			cut1m="$(parseCutoffAge "${1##*=}")"
		else
			rootName="${rootName} ${1}"
		fi
		shift 1
	done
	
	# Define default cutoffs (in days)
	[[ "${cut0}" =~ ^\-?[0-9]+$ ]] || cut0=1    	# keep all snapshots for snapshots up to 1 day old 
	[[ "${cut1h}" =~ ^\-?[0-9]+$ ]] || cut1h=3    	# keep 1 per hour block (up to 24/day) for snapshots between 2-7 days
	[[ "${cut3h}" =~ ^\-?[0-9]+$ ]] || cut3h=7   	# keep 1 per 3 hour block (up to 8/day) for snapshots between 1-2 weeks old
	[[ "${cut6h}" =~ ^\-?[0-9]+$ ]] || cut6h=14   	# keep 1 per 6 hour block (up to 4/day) for snapshots between 3-4 weeks old
	[[ "${cut12h}" =~ ^\-?[0-9]+$ ]] || cut12h=28 	# keep 1 per 12 hour block (up to 2/day) for snapshots between 5-8 weeks old
	[[ "${cut1d}" =~ ^\-?[0-9]+$ ]] || cut1d=56 	# keep 1 per 24 hour block (up to 1/day) for snapshots between 9-16 weeks old 
	[[ "${cut1w}" =~ ^\-?[0-9]+$ ]] || cut1w=112 	# keep 1 per 7 day block (up to 1/week) for snapshots between 17-52 weeks old 
	[[ "${cut1m}" =~ ^\-?[0-9]+$ ]] || cut1m=364 	# keep 1 per month for snapshots between 53-104 weeks (1-2 years) old 
    #       ---------------------->              	# keep 1 per year for snapshots 104+ weeks (2+ years) old 
	
	# Sanity check cutoffs
	(( ${cut0} < 0 )) && cut0=0
	(( ${cut1h} < ${cut0} )) && cut1h=${cut0}
	(( ${cut3h} < ${cut1h} )) && cut3h=${cut1h}
	(( ${cut6h} < ${cut3h} )) && cut6h=${cut3h}
	(( ${cut12h} < ${cut6h} )) && cut12h=${cut6h}
	(( ${cut1d} < ${cut12h} )) && cut1d=${cut12h}
	(( ${cut1w} < ${cut1d} )) && cut1w=${cut1d}
	(( ${cut1m} < ${cut1w} )) && cut1m=${cut1w}

	# Ensure there is a root dataset defined
	[[ -z "${rootName}" ]] && rootName="$(echo $(zpool get name -H -o value))"

	# Display info about cutoffs (unless '-q -q' is given)
	(( ${verboseLevel} > 0 )) && echo -e "\n||---------- SUMMARY OF PROGRAM PARAMETERS ----------|| \n\nTARGET SNAPSHOT DENSITY \t\t AGE \n-------------------------------------------------------\nALL SNAPSHOTS KEPT \t\t\t < ${cut0} day$( (( ${cut0} > 1 )) && echo 's') \n1 every hour    (24 / day) \t\t ${cut0} - ${cut1h} days \n1 every 3 hours  (8 / day) \t\t ${cut1h} - ${cut3h} days \n1 every 6 hours  (4 / day) \t\t ${cut3h} - ${cut6h} days \n1 every 12 hours (2 / day) \t\t ${cut6h} - ${cut12h} days \n1 every 24 hours (daily) \t\t ${cut12h} - ${cut1d} days \n1 every 7 days (weekly) \t\t ${cut1d} - ${cut1w} days \n1 every month (monthly) \t\t ${cut1w} - ${cut1m} days \n1 every year (yearly) \t\t\t > ${cut1m} days \n\nTOP-LEVEL DATASETS SELECTED: ${rootName} \nINCLUDE SUB-DATASETS: $( (( ${nrFlag} == 0 )) && echo "YES" || echo "NO") \n" >&2 && sleep 1


	# # # # # GET SNAPSHOT AGE INFO # # # # #

	# Get time now 
	tNow=$(date +%s)
	
	# Get time at last midnight (start of today)
	tNowDay=$(date --date="$(date | sed -E s/'([0-9]{2}\:[0-9]{2}\:[0-9]{2})'/'12:00:00'/ | sed -E s/'PM'/'AM'/)" +%s)
	
	# Get time at last Monday at midnight (start of this week)
	tNowWeek="${tNowDay}"
	while ! [[ "$(date --date=@${tNowWeek})" == Mon* ]]; do
		tNowWeek=$((( ${tNowWeek} - 86400 )))
	done
	dtNowDayWeek=$((( ( ${tNowDay} - ${tNowWeek} + 1 ) / 86400 )))
		
	# Get current month and year
	curMonth=$(date --date=@${tNow} +%-m)	
	curYear=$(date --date=@${tNow} +%Y)

	# Get sub-dataset names
	mapfile -t dset < <( zfs get name -o value -H $( (( ${nrFlag} > 0 )) || echo '-r' ) ${rootName} | grep -v '@' )
	
	# For each sub-dataset, get snapshots. Remove the oldest snapshot and snapshots matching excluded patterns (if any) from the list.
	mapfile -t snap < <( for dsetName in "${dset[@]}"; do zfs get name -o value -rH "${dsetName}" | grep "${dsetName}"'@' | ( [[ -n "${excludeStr}" ]] && grep -v "${excludeStr}" || tee ) | tail -n +2; done )
	
	# Define function to efficiently break up `date` output into useful ages
	parseDate() {
		# Input to this function is: kk $(date --date=[...] +'%s %-H %Y %-m')
		tSnap[$1]=${2}
		hSnap[$1]=${3}
		dtDay[$1]=$((( ( ${tNowDay} - ${2} + 86400 ) / 86400 )))
		dtWeek[$1]=$((( ( ${dtDay[$1]} - ${dtNowDayWeek} + 7 ) / 7 )))
		dtYear[$1]=$((( ${curYear} - ${4} )))
		dtMonth[$1]=$((( ${curMonth} - ${5} + ( 12 * ${dtYear[$1]} ) )))
	}

	# Loop over snapshots
	for kk in "${!snap[@]}"; do

		parseDate "${kk}" $(date --date="$(zfs get creation -o value -rH "${snap[$kk]}")" +'%s %-H %Y %-m')

		# Print snapshot info (if '-v' is given)
		# Note: these are in terms of the age blocks. e.g., dec 31 2019 will show as 1 year old starting jan 1 2020 , since it falls into last years 1-year-block
		(( ${verboseLevel} > 2 )) && dtSec[$kk]=$((( ${tNow} - ${tSnap[$kk]} ))) && echo -e "|--- # ${kk} ---| \nName: ${snap[$kk]} \nAge: ${dtSec[$kk]} Seconds / ${dtDay[$kk]} Days (Hour = ${hSnap[$kk]}) / Weeks = ${dtWeek[$kk]} Weeks / Months = ${dtMonth[$kk]} Months / Years = ${dtYear[$kk]} Years\n" >&2
		
		((kk++))
	
	done

	# Determine unique ages (in days/weeks) and filter out ages that cant be used due to chosen cutoff values
	ageWeekMin=$((( ${cut1d} / 7 )))
	ageMonthMin=$((( $((( ${curMonth} - $(date --date=@$((( ${tNow} - ( ${cut1w} * 86400 ) ))) +%-m) ))) + $((( ${curYear} - $(date --date=@$((( ${tNow} - ( ${cut1w} * 86400 ) ))) +%Y) ))) * 12 )))
	ageYearMin=$((( ${curYear} - $(date --date=@$((( ${tNow} - ( ${cut1m} * 86400 ) ))) +%Y) )))
	mapfile -t dtDayUniq < <(printf '%s\n' "${dtDay[@]}" | sort -ug | while read -r kk; do (( ${kk} > ${cut0} )) && echo "${kk}"; done)
	mapfile -t dtWeekUniq < <(printf '%s\n' "${dtWeek[@]}" | sort -ug | while read -r kk; do (( ${kk} >= ${ageWeekMin} )) && echo "${kk}"; done)
	mapfile -t dtMonthUniq < <(printf '%s\n' "${dtMonth[@]}" | sort -ug | while read -r kk; do (( ${kk} >= ${ageMonthMin} )) && echo "${kk}"; done)
	mapfile -t dtYearUniq < <(printf '%s\n' "${dtYear[@]}" | sort -ug | while read -r kk; do (( ${kk} >= ${ageYearMin} )) && echo "${kk}"; done)

	# # # # # DETERMINE WHICH SNAPSHOTS TO REMOVE AND DESTROY THEM # # # # #
	
	# Loop over sub-datasets
	for dsetName in "${dset[@]}"; do
	
		# Isolate indices for current sub-dataset 
		kkCur0="$(for kk in "${!snap[@]}"; do [[ "${snap[$kk]}" == "${dsetName}"'@'* ]] && echo "${kk}"; done)"
		[[ -z "${kkCur0}" ]] && continue 

		kkCur0w=""
		kkCur0m=""
		kkCur0y=""
	
		# Loop over ages (in days)
		for ageDays in "${dtDayUniq[@]}"; do
	
			# Isolate indices for current age (in days)
			kkCur1="$(for kk in ${kkCur0}; do [[ "${dtDay[$kk]}" == "${ageDays}" ]] && echo "${kk}"; done | sort -rg)"
			[[ -z "${kkCur1}" ]] && continue

			# If above the daily (24-hour block) cutoff, specify these indices for weekly/monthly/yearly snapshots
			(( ${ageDays} > ${cut1d} )) && (( ${ageDays} <= ${cut1w} )) && kkCur0w+=" $(echo ${kkCur1})" && continue
			(( ${ageDays} > ${cut1w} )) && (( ${ageDays} <= ${cut1m} )) && kkCur0m+=" $(echo ${kkCur1})" && continue
			(( ${ageDays} > ${cut1m} )) && kkCur0y+=" $(echo ${kkCur1})" && continue
	
			# Determine hour block size
			if (( ${ageDays} <= ${cut1h} )); then
				dh=1
			elif (( ${ageDays} <= ${cut3h} )); then
				dh=3
			elif (( ${ageDays} <= ${cut6h} )); then
				dh=6
			elif (( ${ageDays} <= ${cut12h} )); then
				dh=12
			elif (( ${ageDays} <= ${cut1d} )); then
				dh=24
			fi
	
			# Print debug info (if '-v -v' is given)
			(( ${verboseLevel} > 3 )) && echo "dataset name: ${dsetName} -- block-size: $dh hours -- age: ${ageDays} days -- kk:"${kkCur1} >&2
	
			# Loop over N-hour blocks
			for hBlockStart in $(eval echo "{0..23..${dh}}"); do
				
				# Loop over snapshots falling in the N-hour block. 
				# Keep the youngest snapshot that falls in the block and destroy the rest.
				tripFlag=0
				for kk in ${kkCur1}; do

					# Check if the snapshot falls into the current N-hour block
					# Print info about what is being kept and what is being removed (unless '-q' is given)
					if (( ( ${hSnap[$kk]} + 1 ) > ${hBlockStart} )) && (( ${hSnap[$kk]} < ( ${hBlockStart} + ${dh} ) )); then
						if (( ${tripFlag} == 0 )); then

							# Keep the snapshot and trip the flag
							tripFlag=1
							(( ${verboseLevel} > 1 )) && echo "-> KEEPING ${snap[$kk]}" >&2

						else

							# Destroy the snapshot
							(( ${verboseLevel} > 1 )) && echo "DESTROYING ${snap[$kk]} <-----" >&2
							( (( ${drFlag} > 0 )) && echo "zfs destroy ${snap[$kk]}" ) || zfs destroy "${snap[$kk]}"

						fi
					fi
	
				done
			done
		done
		
		# Loop over ages (in weeks)
		for ageWeeks in "${dtWeekUniq[@]}"; do
	
			# Isolate indices for current age (in weeks)
			kkCur1w="$(for kk in ${kkCur0w}; do [[ "${dtWeek[$kk]}" == "${ageWeeks}" ]] && echo "${kk}"; done | sort -rg)"
			[[ -z "${kkCur1w}" ]] && continue
	
			# Print debug info (if '-v -v' is given)
			(( ${verboseLevel} > 3 )) && echo "dataset name: ${dsetName} -- block-size: 7 days (1 week) -- age: ${ageWeeks} weeks -- kk:"${kkCur1} >&2
			
			# Loop over snapshots falling in each 1-week long block. 
			# Keep the youngest snapshot that falls in the block and destroy the rest.
			tripFlag=0
			for kk in ${kkCur1w}; do

				# Print info about what is being kept and what is being removed (unless '-q' is given)
				if (( ${tripFlag} == 0 )); then

					# Keep the snapshot and trip the flag
					tripFlag=1
					(( ${verboseLevel} > 1 )) && echo "-> KEEPING ${snap[$kk]}" >&2

				else

					# Destroy the snapshot
					(( ${verboseLevel} > 1 )) && echo "DESTROYING ${snap[$kk]} <-----" >&2
					( (( ${drFlag} > 0 )) && echo "zfs destroy ${snap[$kk]}" ) || zfs destroy "${snap[$kk]}"

				fi
	
			done
		done


		# Loop over ages (in months)
		for ageMonths in "${dtMonthUniq[@]}"; do
	
			# Isolate indices for current age (in months)
			kkCur1m="$(for kk in ${kkCur0m}; do [[ "${dtMonth[$kk]}" == "${ageMonths}" ]] && echo "${kk}"; done | sort -rg)"
			[[ -z "${kkCur1m}" ]] && continue
	
			# Print debug info (if '-v -v' is given)
			(( ${verboseLevel} > 3 )) && echo "dataset name: ${dsetName} -- block-size: 1 month -- age: ${ageMonths} months -- kk:"${kkCur1} >&2
			
			# Loop over snapshots falling in each 1-month long block. 
			# Keep the youngest snapshot that falls in the block and destroy the rest.
			tripFlag=0
			for kk in ${kkCur1m}; do

				# Print info about what is being kept and what is being removed (unless '-q' is given)
				if (( ${tripFlag} == 0 )); then

					# Keep the snapshot and trip the flag
					tripFlag=1
					(( ${verboseLevel} > 1 )) && echo "-> KEEPING ${snap[$kk]}" >&2

				else

					# Destroy the snapshot
					(( ${verboseLevel} > 1 )) && echo "DESTROYING ${snap[$kk]} <-----" >&2
					( (( ${drFlag} > 0 )) && echo "zfs destroy ${snap[$kk]}" ) || zfs destroy "${snap[$kk]}"

				fi
	
			done
		done


		# Loop over ages (in years)
		for ageYears in "${dtYearUniq[@]}"; do
	
			# Isolate indices for current age (in years)
			kkCur1y="$(for kk in ${kkCur0y}; do [[ "${dtYear[$kk]}" == "${ageYears}" ]] && echo "${kk}"; done | sort -rg)"
			[[ -z "${kkCur1y}" ]] && continue
	
			# Print debug info (if '-v -v' is given)
			(( ${verboseLevel} > 3 )) && echo "dataset name: ${dsetName} -- block-size: 1 year -- age: ${ageYears} years -- kk:"${kkCur1} >&2
			
			# Loop over snapshots falling in each 1-Year long block. 
			# Keep the youngest snapshot that falls in the block and destroy the rest.
			tripFlag=0
			for kk in ${kkCur1y}; do

				# Print info about what is being kept and what is being removed (unless '-q' is given)
				if (( ${tripFlag} == 0 )); then

					# Keep the snapshot and trip the flag
					tripFlag=1
					(( ${verboseLevel} > 1 )) && echo "-> KEEPING ${snap[$kk]}" >&2

				else

					# Destroy the snapshot
					(( ${verboseLevel} > 1 )) && echo "DESTROYING ${snap[$kk]} <-----" >&2
					( (( ${drFlag} > 0 )) && echo "zfs destroy ${snap[$kk]}" ) || zfs destroy "${snap[$kk]}"

				fi
	
			done
		done

	done
	
	return 0
}

 zfsSetupAutoRemoveSnapshotService() {
    # Sets up and enables a systemd service and a systemd timer to run `zfsAutoRemoveSnapshots` every day at midnight

    # Setup systemd service
    cat << EOF | sudo tee /lib/systemd/system/my-zfs-autoremove-snapshots.service
[Unit]
Description=Runs zfsAutoRemoveSnapshots to smartly cleanup old ZFS snapshots

[Service]
Type=oneshot
ExecStart=/bin/bash -c '. ${BASH_SOURCE[0]} && zfsAutoRemoveSnapshots'

[Install] 
WantedBy=default.target
EOF

    # setup systemd timer
    cat << EOF | sudo tee /lib/systemd/system/my-zfs-autoremove-snapshots.timer
[Unit]
Description=Timer to run my-zfs-autoremove-snapshots.service daily to automatically remove old ZFS snapshots

[Timer]
Unit=my-zfs-autoremove-snapshots.service
OnCalendar=*-*-* 00:00:00
Persistent=true

[Install]
WantedBy=default.target
EOF

    # enable timer
    sudo systemctl daemon-reload    
    sudo systemctl enable my-zfs-autoremove-snapshots.timer

}


zfsSetupAutoSnapshotService() {
    # Sets up and enables a systemd service and a systemd timer to snapshot all ZFS datasets hourly

    # Setup systemd service
    cat << EOF | sudo tee /lib/systemd/system/my-zfs-auto-snapshot.service
[Unit]
Description=Snapshots all ZFS datasets currently active on the system

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/sbin/zpool get name -o value -H | while read -r nn; do /sbin/zfs snapshot -r "$nn@\$(date +%Y-%m-%d_%H:%M:%S)"; done'

[Install] 
WantedBy=default.target
EOF

    # setup systemd timer
    cat << EOF | sudo tee /lib/systemd/system/my-zfs-auto-snapshot.timer
[Unit]
Description=Timer to run my-zfs-auto-snapshot.service hourly to automatically create ZFS snapshots

[Timer]
Unit=my-zfs-auto-snapshot.service
OnCalendar=*-*-* *:00:00
Persistent=true

[Install]
WantedBy=default.target
EOF

    # enable timer
    sudo systemctl daemon-reload    
    sudo systemctl enable my-zfs-auto-snapshot.timer

}



