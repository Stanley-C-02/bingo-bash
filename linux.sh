#!/bin/bash
#source: LINUX
#Plays a game of LINUX (bingo)
#s46chow, Chow, Stanley, 501022142, 10
#Resources used:
#https://unixutils.com/string-manipulation-with-bash/

# $1 is a file name to count the lines of
lines () {
	echo $(wc -l "$1" | cut -d' ' -f1)
}

# $1 is a string, which is tested to be 0, 1, 2, ...
isNaturalNumber () {
	if [[ $1 == +([[:digit:]]) ]] ; then
		echo T
	fi
}

# $1 is a string representing the board whose validity will be checked
isValidCard () {
	local s=' '
	local n='
'
	local v0='(0[1-9]|1[0-5]) '
	local v1='(1[6-9]|2[0-9]|30) '
	local v2='(3[1-9]|4[0-5]) '
	local v3='(4[6-9]|5[0-9]|60) '
	local v4='(6[1-9]|7[0-5])'
	local row="($v0$v1$v2$v3$v4)"
	local re="^($row$n){2}"
	      re+="($v0$v1)00$s($v3$v4)"
	      re+="($n$row){2}$"
	if [[ "$1" =~ $re && $(echo "$1" | tr ' ' '\n' | sort -u | wc -l) -eq 25 ]] ; then
		echo T
	fi
}

# $1 is a string of space-separated values which will be used in the 2D associative array
read2DArray () {
	local -i i=0 j=0
	for val in $1 ; do
		echo -n "[$i,$j]=${val} "
		j+=1
		if [ $j -eq $2 ] ; then
			j=0
			i+=1
		fi
	done
}

# Returns a 2D associative array of the marked cells (acts as suffixes to card numbers), has no parameters
getDefaultMarks () {
	for i in {0..4} ; do
		for j in {0..4} ; do
			if [ $j -ne 4 ] ; then
				echo -n "[$i,$j]='  ' "
			else
				echo -n "[$i,$j]='\n' "
			fi
		done
	done
}

printCard () {
	local output=' L   I   N   U   X'
	output+='\n'
	
	for i in {0..4} ; do
		for j in {0..4} ; do
			output+="${cardValues[$i,$j]}${marks[$i,$j]}"
		done
	done
	
	echo -e -n "$output"
}

# $1 is a 2D associative array key; marks the given cell if it exists in the user's card
mark () {
	for i in {0..4} ; do
		for j in {0..4} ; do
			if [ ${cardValues[$i,$j]} == $1 ] ; then
				case ${marks[$i,$j]} in
					'  ')	marks[$i,$j]='m '	;;
					'\n')	marks[$i,$j]='m\n'	;;
				esac
			fi
		done
	done
}

#Pops a value from the remainingValues array, adds it to the call list and marks it if the card has the number
callNumber () {
	if [ ${#remainingValues[*]} -eq 0 ] ; then
		echo "all numbers called" > /dev/stderr
		exit 5
	fi
	
	local nextIndex=$((RANDOM % ${#remainingValues[*]}))
	local nextVal=${remainingValues[$nextIndex]}
	local nextLabel=${labels[$(((10#$nextVal - 1) / 15))]}
	
	remainingValues=(${remainingValues[*]/$nextVal})
	
	callList+=" $nextLabel$nextVal"
	mark $nextVal
}

updateBoardStatus () {
	if [ "${marks[0,0]::1}" == "m" -a \
	     "${marks[0,4]::1}" == "m" -a \
	     "${marks[4,0]::1}" == "m" -a \
	     "${marks[4,4]::1}" == "m" ] ; then
		isWin=T
	else
		for i in {0..4} ; do
			if [ "${marks[0,$i]::1}" == "m" -a \
			     "${marks[1,$i]::1}" == "m" -a \
			     "${marks[2,$i]::1}" == "m" -a \
			     "${marks[3,$i]::1}" == "m" -a \
			     "${marks[4,$i]::1}" == "m" -o \
			     "${marks[$i,0]::1}" == "m" -a \
			     "${marks[$i,1]::1}" == "m" -a \
			     "${marks[$i,2]::1}" == "m" -a \
			     "${marks[$i,3]::1}" == "m" -a \
			     "${marks[$i,4]::1}" == "m" ] ; then
				isWin=T
				break
			fi
		done
	fi
}

printBoardStatus () {
	if [ $isWin ] ; then
		echo "WINNER"
	else
		echo -n "enter eny key to get a call or q to quit: "
	fi

}



if ! [ -r "$1" ] ; then
	echo "input file missing or unreadable" > /dev/stderr
	exit 1
elif [ $(lines $1) -ne 6 ] ; then
	echo "input file must have 6 lines" > /dev/stderr
	exit 2
elif ! [ $(isNaturalNumber "$(head -1 "$1")") ] ; then
	echo "seed line format error" > /dev/stderr
	exit 3
elif ! [[ $(isValidCard "$(cat "$1" | tail -5)") ]] ; then
	echo "card format error" > /dev/stderr
	exit 4
fi



typeset -a labels=(L I N U X)
typeset -a callList
typeset -a remainingValues=($(seq -w 1 75))
typeset -A cardValues="($(read2DArray "$(cat "$1" | tail -5 | tr '\n' ' ')" 5 5))"
typeset -A marks="($(getDefaultMarks))"
typeset -i isWon
mark 00
RANDOM=$(cat "$1" | head -1)

clear
echo "CALL LIST:${callList[*]}"
printCard
updateBoardStatus
printBoardStatus

while read -n1 input ; do
	if [ "$(echo "$input" | tr [[:lower:]] [[:upper:]])" == 'Q' ] ; then
		break
	fi
	
	callNumber
	
	clear
	echo "CALL LIST:${callList[*]}"
	printCard
	updateBoardStatus
	printBoardStatus
	
	if [ "$isWin" ] ; then
		break
	fi
done

exit 0

