#!/bin/bash

# Remove spaces at the beginning and at the end of a character string
trim() {
	RESULT=$(echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
	echo $RESULT
}

# Write ANSI-compatible statements
ansi() {
	if [ "$1" = "reset" ]; then
		tput sgr0
	elif [ "$1" = "bold" ]; then
		tput bold
	elif [ "$1" = "dim" ]; then
		tput dim
	elif [ "$1" = "rev" ]; then
		tput rev
	elif [ "$1" = "under" ]; then
		tput smul
	elif [ "$1" = "fg" ]; then
		case "$2" in
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
	elif [ "$1" = "bg" ]; then
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
		esac
	fi
}

echo
echo " $(ansi bg magenta)                                              $(ansi reset)"
echo " $(ansi bg magenta) $(ansi reset)                                            $(ansi bg magenta) $(ansi reset)"
echo " $(ansi bg magenta) $(ansi reset)$(ansi fg cyan)        Arkiv Configuration Editor         $(ansi reset) $(ansi bg magenta) $(ansi reset)"
echo " $(ansi bg magenta) $(ansi reset)                                            $(ansi bg magenta) $(ansi reset)"
echo " $(ansi bg magenta)                                              $(ansi reset)"
echo
# Amazon S3
read -p " $(ansi fg yellow)Archive to Amazon S3? [Y/n]$(ansi reset) " ANSWER
if [ "$ANSWER" = "n" ] || [ "$ANSWER" = "N" ]; then
	CONF_AWS_S3="no"
	echo "AWS_S3=no" >> ~/.arkiv
else
	CONF_AWS_S3="yes"
	echo "AWS_S3=yes" >> ~/.arkiv
	read -p " $(ansi fg yellow)Bucket name?$(ansi reset) " ANSWER
	if [ "$ANSWER" = "" ]; then
		echo "$(ansi fg red) ⚠ Bad bucket name$(ansi reset)"
		exit 1
	fi
	CONF_S3_BUCKET=$(trim "$ANSWER")
fi
# local archive path
read -p " $(ansi fg yellow)Path to local archives? [$(ansi reset)/var/archives$(ansi fg yellow)]$(ansi reset) " ANSWER
CONF_LOCAL_PATH=$(trim "$ANSWER")
if [ "$CONF_LOCAL_PATH" = "" ]; then
	CONF_LOCAL_PATH="/var/archives"
fi
if [ ! -d $CONF_LOCAL_PATH ]; then
	read -p " $(ansi fg red)⚠ Directory '$ANSWER' doesn't exist. Create it? [Y/n]$(ansi reset) " ANSWER
	if [ "$ANSWER" = "n" ] || [ "$ANSWER" = "N" ]; then
		echo " $(ansi fg red)⚠ ABORT$(ansi reset)"
		exit 1
	fi
	if ! mkdir $CONF_LOCAL_PATH; then
		echo " $(ansi fg red)⚠ Unable to create directory. ABORT$(ansi reset)"
		exit 1
	fi
fi
# path to backup
read -p " $(ansi fg yellow)Paths to backup? (separated with spaces)$(ansi reset) $(ansi dim)(example: $(ansi reset)/home /etc$(ansi dim))$(ansi reset) " ANSWER
CONF_SRC=$(trim "$ANSWER")
if [ "$CONF_SRC" = "" ]; then
	echo " $(ansi fg red)⚠ Nothing to backup. ABORT$(ansi reset)"
	exit 1
fi
# MySQL
CONF_MYSQL="no"
read -p " $(ansi fg yellow)Backup MySQL databases? [Y/n]$(ansi reset) " ANSWER
if [ "$ANSWER" != "n" ] && [ "$ANSWER" != "N" ]; then
	CONF_MYSQL="yes"
	read -p " $(ansi fg yellow)MySQL user?$(ansi reset) $(ansi dim)(example: $(ansi reset)root$(ansi dim))$(ansi reset) " ANSWER
	CONF_MYSQL_USER=$(trim "$ANSWER")
	if [ "$CONF_MYSQL_USER" = "" ]; then
		echo " $(ansi fg red)⚠ Empty user name. ABORT$(ansi reset)"
		exit 1
	fi
	read -s -p " $(ansi fg yellow)MySQL password?$(ansi reset) " ANSWER
	CONF_MYSQL_PWD=$(trim "$ANSWER")
	if [ "$CONF_MYSQL_PWD" = "" ]; then
		echo " $(ansi fg red)⚠ Empty password. ABORT$(ansi reset)"
		exit 1
	fi
	echo
	read -p " $(ansi fg yellow)List of databases? (separated with spaces)$(ansi reset) " ANSWER
	CONF_MYSQL_BASES=$(trim "$ANSWER")
	if [ "$CONF_MYSQL_BASES" = "" ]; then
		echo " $(ansi fg red)⚠ No database to backup. ABORT$(ansi reset)"
		exit 1
	fi
fi
# local purge
read -p " $(ansi fg yellow)Delay for local purge?$(ansi reset) $(ansi dim)(examples: \"$(ansi reset)3 days$(ansi dim)\" \"$(ansi reset)2 weeks$(ansi dim)\" \"$(ansi reset)2 months$(ansi dim)\")$(ansi reset) " ANSWER
CONF_LOCAL_PURGE_DELAY=$(trim "$ANSWER")
if [ "$CONF_LOCAL_PURGE_DELAY" = "" ]; then
	read -p " $(ansi fg red)⚠ Are you sure you want to never purge any backup file? [y/N] " ANSWER
	if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
		echo " $(ansi fg red)⚠ Empty purge delay. ABORT$(ansi reset)"
		exit 1
	fi
fi
# S3 purge
read -p " $(ansi fg yellow)Delay for Amazon S3 purge?$(ansi reset) $(ansi dim)(examples: \"$(ansi reset)3 days$(ansi dim)\" \"$(ansi reset)2 weeks$(ansi dim)\" \"$(ansi reset)2 months$(ansi dim)\")$(ansi reset) " ANSWER
CONF_S3_PURGE_DELAY=$(trim "$ANSWER")
if [ "$CONF_S3_PURGE_DELAY" = "" ]; then
	read -p " $(ansi fg red)⚠ Are you sure you want to never purge any archived file? [y/N] " ANSWER
	if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
		echo " $(ansi fg red)⚠ Empty purge delay. ABORT$(ansi reset)"
		exit 1
	fi
fi

# write result
read -p " $(ansi fg yellow)Ready to erase file '$(ansi reset)~/.arkiv$(ansi fg yellow)' and rebuild it? [y/N]$(ansi reset) " ANSWER
if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
	echo " $(ansi fg red)⚠ ABORT$(ansi reset)"
	exit 1
fi
if ! rm ~/.arkiv ||
   ! touch ~/.arkiv ||
   ! chmod 600 ~/.arkiv; then
	echo " $(ansi fg red)⚠ Unable to manage the file '$(ansi reset)~/.arkiv$(ansi fg red)'. ABORT$(ansi reset)"
	exit 1
fi
echo "AWS_S3=$CONF_AWS_S3" >> ~/.arkiv
if [ "$CONF_AWS_S3" = "yes" ]; then
	echo "S3_BUCKET=$CONF_S3_BUCKET" >> ~/.arkiv
fi
echo "LOCAL_PATH=$CONF_LOCAL_PATH" >> ~/.arkiv
echo "SRC=$CONF_SRC" >> ~/.arkiv
echo "MYSQL=$CONF_MYSQL" >> ~/.arkiv
if [ "$CONF_MYSQL" = "yes" ]; then
	echo "MYSQL_USER=$CONF_MYSQL_USER" >> ~/.arkiv
	echo "MYSQL_PWD=$CONF_MYSQL_PWD" >> ~/.arkiv
fi
echo "LOCAL_PURGE_DELAY=$CONF_LOCAL_PURGE_DELAY" >> ~/.arkiv
echo "S3_PURGE_DELAY=$CONF_S3_PURGE_DELAY" >> ~/.arkiv

