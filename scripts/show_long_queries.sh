#!/bin/bash
#
# Author : Vamsi krishna
# Desc   : Shows long running queries


# CONSTANTS
DEBUG=1
CLIENT="/usr/bin/mysql"
HOST=$2
MYSQL_CMD="Query Quit Refresh Processlist" 
IGNORE_LIST=""
LOGFILE=/var/log/show-long-${HOST}.log
DEBUGLOG=/var/log/show-long-${HOST}.debug


# Functions
getfile() {
   for line in `cat $1`
   do
        clean=`echo $line|tr -d ' \t'|cut -d'#' -f1`
        IGNORE_LIST="$IGNORE_LIST $clean"
   done
}

DEBUGLOG() {
	if [ $DEBUG -eq 1 ]; then
		echo "[`date +'%Y-%m-%d %H:%M:%S'`]: $1" >> $DEBUGLOG
	fi
}

LOG() {
	echo "[`date +'%Y-%m-%d %H:%M:%S'`]: $1" | tee -a $LOGFILE
	DEBUGLOG "$1"
}

LOG2() {
	echo "[`date +'%Y-%m-%d %H:%M:%S'`]: $1" >> $LOGFILE
	DEBUGLOG "$1"
}

if [ ! -d $(dirname $LOGFILE) ]; then
	mkdir -p $(dirname $LOGFILE)
fi

p=0
longest_running=0

mainloop() {
	DEBUGLOG "Setting IFS=<newline>"
   IFS="
"
#	DEBUGLOG "Looping through all lines returned by [$CLIENT -h$HOST -u$DBUSER -p$DBPASS -B -e"show processlist"|grep -iv "Id"|awk -F '\t' '{print $1";"$2";"$3";"$5";"$6}']"
   for line in `$CLIENT -h$HOST -u$DBUSER -p$DBPASS -BNe"show processlist"|awk -F '\t' '{print $1";"$2";"$3";"$5";"$6}'`
   do
        i=0
        user_hit=1
        cmd_hit=0

	DEBUGLOG "Setting IFS=';'"
        IFS=";"

	DEBUGLOG "Looping through $line"
        for val in $line
        do
                args[$i]=$val
                i=$(($i+1))
        done

	DEBUGLOG "Setting IFS=' '"
        IFS=" "

	DEBUGLOG "Setting vars"
        id=${args[0]}
        user=${args[1]}
		host=${args[2]}
        cmd=${args[3]}
        time=${args[4]}
	DEBUGLOG "Env. vars: id[$id], user[$user], host[$host], cmd[$cmd], time[$time]"

	DEBUGLOG "Checking ignore list:'$IGNORE_LIST'"
        for ignore_user in $IGNORE_LIST
        do
                [ $ignore_user = $user ] && user_hit=0 && break
        done

	DEBUGLOG "Checking if [$cmd] in [$MYSQL_CMD]"
        for mcmd in $MYSQL_CMD
        do
                [ "$mcmd" = "$cmd" ] && cmd_hit=1 && break
        done

	DEBUGLOG "If we have a command hit - Check if [$time] is greater than [$longest_running] and save"
	if [ $cmd_hit -eq 1 -a $time -gt $longest_running ]; then
		DEBUGLOG "Setting longest_running=$time"
		longest_running=$time
		longest_query="$($CLIENT -h$HOST -u$DBUSER -p$DBPASS -e'show full processlist' | grep $id | sed 's/\\n/\n/g')"
		DEBUGLOG "Longest query: $longest_query"
	else
		DEBUGLOG "time[$time], longest_running[$longest_running], cmd_hit[$cmd_hit]"
	fi

	DEBUGLOG "Are we reporting anything back for this line? [user_hit=$user_hit, time=$time, LQT=$LQT, cmd_hit=$cmd_hit]"
        if [ $user_hit -eq 1 -a $time -gt $LQT -a $cmd_hit -eq 1 ]; then
		DEBUGLOG "Yes we are!"
		if [ $p -eq 0 ]; then
			LOG "=== FOUND FOLLOWING QUERIES RUNNING LONGER THAN $LQT SECONDS ==="
		fi
		p=$(($p+1))
		HOSTNAME=$($CLIENT -h$HOST -u$DBUSER -p$DBPASS -BNe'SELECT @@hostname')
                LOG "[$HOST/$HOSTNAME]: thread_id:$id, user:$user, host:$host, elapsed_time:$time, command:$cmd. Full query below: "
		LOG "$($CLIENT -h$HOST -u$DBUSER -p$DBPASS -e'show full processlist' | grep $id | sed 's/\\n/\n/g'|cut -f 8-)"
		LOG "=========="
        else
		DEBUGLOG "No, we're not!"
	fi
   done
	if [ $p -gt 0 ]; then
		LOG "Found $p long running queries"
	fi
}

usage() {
   echo "Usage: $0 <Long Query Time> <host> [Ignore File]"
   echo "     Long Query Time - If Time in 'show processlist' is greater than"
   echo "                       Long Query Time (seconds) then this script will display them"
   echo	"     Host	      - host to connect to"
   echo "     Ignore File     - A list of database users that are ignored by this script"
}

[ $# -lt 2 ] && usage $0 && exit 1
LQT=$1

[ $# -eq 3 ] && getfile $3

LOG "Runnning check on [$HOST] with long query time trigger (LQT): ${LQT}s"
mainloop

if [ $longest_running -gt 0 ]; then
	LOG "Longest running query found:${longest_running}s"
	LOG2 "Processlist: $longest_query"
fi

exit 0