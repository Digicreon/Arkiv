#!/bin/bash

# find_in_list()
# Tell if a string is an item of a list.
# @param	string	The list.
# @param	string	The item to search.
# @return	string	The item if it was found.
find_in_list() {
	for ITEM in $1; do
		if [ "$ITEM" = "$2" ]; then
			echo "$ITEM"
			return
		fi
	done
}

# align_spaces()
# Print as many spaces as the string given in parameter.
# @param	string	The string which length will be used.
# @param	string	(optional) Increment or decrement of the length ("+1", "-3", ...).
align_spaces() {
	LEN=$((${#1} $2))
	printf "%0.s " $(seq 1 $LEN)
}

# trim()
# Remove spaces at the beginning and at the end of a character string.
# @param	string	The string to trim.
trim() {
	RESULT=$(echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
	echo $RESULT
}

# filenamize()
# Convert a string that contains a path to a file, and return a string suitable as a file name.
# Replace slashes and spaces by dashes.
# @param	string	The string to modify.
filenamize() {
	RESULT=$(echo "$1" | sed 's/[[:space:]]\+/-/g' | sed 's/\//-/g' | sed -e 's/^-*//' -e 's/-*$//' | sed 's/-\+/-/g')
	echo $RESULT
}

# ansi()
# Write ANSI-compatible statements.
# @param	string	Command:
#			- reset: Remove all decoration.
#			- bold:  Write text in bold.
#			- dim:   Write faint text.
#			- rev:   Write text in reverse video. Could take another parameter with the background color.
#			- under: Write underlined text.
#			- black, red, green, yellow, blue, magenta, cyan, white: Change the text color.
ansi() {
	if [ "$TERM" = "" ] || [ "$OPT_NOANSI" = "1" ]; then
		return
	fi
	if ! type tput > /dev/null; then
		return
	fi
	case "$1" in
		"reset")	tput sgr0
		;;
		"bold")		tput bold
		;;
		"dim")		tput dim
		;;
		"rev")
			case "$2" in
				"black")	tput setab 0
				;;
				"red")		tput setab 1
				;;
				"green")	tput setab 2
				;;
				"yellow")	tput setab 3
				;;
				"blue")		tput setab 4
				;;
				"magenta")	tput setab 5
				;;
				"cyan")		tput setab 6
				;;
				"white")	tput setab 7
				;;
				*)		tput rev
			esac
		;;
		"under")	tput smul
		;;
		"black")	tput setaf 0
		;;
		"red")		tput setaf 1
		;;
		"green")	tput setaf 2
		;;
		"yellow")	tput setaf 3
		;;
		"blue")		tput setaf 4
		;;
		"magenta")	tput setaf 5
		;;
		"cyan")		tput setaf 6
		;;
		"white")	tput setaf 7
		;;
	esac
}

# warn()
# Write a warning message.
# @param	string	The text to write.
warn() {
	echo "$(ansi yellow)⚠$(ansi reset) $1"
}

# abort()
# Write an error message and exit.
abort() {
	echo "$(ansi red)⛔$(ansi reset) $1 $(ansi red)ABORT$(ansi reset)"
	# go back to previous directory
	if [ "$_NEED_POPD" -eq 1 ]; then
		popd > /dev/null
	fi
	exit 1
}

# success()
# Write a success message and exit. Called by Dispak itself, no need to call it from inside a rule.
success() {
	echo "$(ansi green)✓ Success$(ansi reset)"
	# go back to previous directory
	if [ "$_NEED_POPD" -eq 1 ]; then
		popd > /dev/null
	fi
	exit 0
}

