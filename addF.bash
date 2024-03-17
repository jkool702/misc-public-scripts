#!/usr/bin/env bash

addF () {
## pure-bash addition for ints + floats (i.e., for numbers optionally with decimals)
# output will have the same number of decimal places as the input with the most decimal places

    local -a dA iA;
    local -i i d dMax jj;
    
    i=0;
    dMax=0;
    
    # get integer and decimal parts in arrays
    dA=("${@//*./.}");
    iA=("${@%%.*}");
    
    for ((jj=0; jj<$#; jj++ )); do
        # remove leading 0's from integers
        while [[ "${iA[$jj]}" == '0'* ]] || [[ "${iA[$jj]}" == '-0'* ]]; do
            iA[$jj]="${iA[$jj]#0}"
            iA[$jj]="${iA[$jj]//-0/-}"
        done
        
        # integer cummulative sum
        [[ "${iA[$jj]#-}" ]] && i+="${iA[$jj]}";
        
        # keep track of the which decimal has the most digits (maxD)
        # check if this input has a decimal
        if [[ "${dA[$jj]}" == .[0-9]* ]]; then
            # has decimal. update maxD if this inpout has more digits
            (( "${#dA[$jj]}" > "$dMax" )) && dMax="${#dA[$jj]}";
            [[ "${iA[$jj]:0:1}" == '-' ]] && dA[$jj]=-"${dA[$jj]}";
        else
            # no decimal. remove input from dA
            unset "dA[$jj]";
        fi;
    done;
    
    (( ${dMax} == 0 )) || {
        # add trailing 0's to make decimals all have the same number of digits
        
        ((dMax--));
        dA=($(printf '%.'"$dMax"'f ' "${dA[@]}"));
        dA=("${dA[@]#0.}");
        dA=("${dA[@]//-0./-}");
        
        if [[ ${#dA[@]} == 0 ]]; then
            d=0;
        else
            d=$(( $(printf '%d + ' "${dA[@]#.}") 0 ));
        fi;
    }
    
    if [[ "${dMax}" == 0 ]]; then
        # no decimals. print the integer sum and return
        printf '%s\n' "$i";
    
    elif [[ "${i:0:1}" == '-' ]]; then
        # integer is positive
        # Add/subtract 1 from integer until decimal sum is between 0 and 1
        until (( d > ( -1 * ( 10 ** dMax ) ) )); do
            d+="$(( 10 ** dMax ))";
            ((i--));
        done;
        until (( d <= 0 )); do
            d+="-$(( 10 ** dMax ))";
            ((i++));
        done;
        
        # print combined sum and return
        printf '%d.%0'"${dMax}"'d\n' "$i" "${d#-}";
        
    else
        # integer is negative
        # Add/subtract 1 from integer until decimal sum is between -1 and 0
        until (( d >= 0 )); do
            d+="$(( 10 ** dMax ))";
            ((i--));
        done;
        until (( d < ( 10 ** dMax ) )); do
            d+="-$(( 10 ** dMax ))";
            ((i++));
        done;
        
        # print combined sum and return
        printf '%d.%0'"${dMax}"'d\n' "$i" "$d";
    fi;
}
