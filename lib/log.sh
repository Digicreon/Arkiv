#!/bin/bash

# log()
# Write a character string with the current date before it to stdout or to the log file.
# @param	string	The text to write.
log() {
	if [ "$1" = "-n" ]; then
		STR="$2"
	else
		STR="$(ansi dim)[$(date +"%Y-%m-%d %H:%M:%S%:z")]$(ansi reset) $1"
	fi
	# write to stdout unless it is disabled
	if [ "$OPT_NOSTDOUT" != "1" ]; then
		echo $STR
	fi
	# write to log file
	if [ "$OPT_LOG_PATH" != "" ]; then
		echo "$STR" >> "$(eval realpath "$OPT_LOG_PATH")"
	fi
	# write to syslog
	if [ "$OPT_SYSLOG" = "1" ]; then
		logger --tag arkiv --priority user.warning "$TXT"
	fi
}

# err()
# Write a character string with the current date before it to stderr or to the log file.
# @param	string	The text to write.
err() {
	CURDATE=`date +"%Y-%m-%d %H:%M:%S%:z"`
	STR="$(ansi dim)[$CURDATE]$(ansi reset) $1"
	# write to stderr unless it is disabled
	if [ "$OPT_NOSTDOUT" != "1" ]; then
		(>&2 echo "$STR")
	fi
	# write to log file
	if [ "$OPT_LOG_PATH" != "" ]; then
		echo "$STR" >> "$(eval realpath "$OPT_LOG_PATH")"
	fi
	# write to syslog
	if [ "$OPT_SYSLOG" = "1" ]; then
		logger --tag arkiv --priority user.warning "$TXT"
	fi
}
