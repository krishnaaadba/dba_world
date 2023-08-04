#!/bin/bash
#
# Author: Vamsi krishna
# Desc  : This is a library of functions for mysql administration
#         source this file in you home ~/.bashrc file

# A hidden config file [~/.my.cfg] with login credentials is assumed to be present
source ~/.my.cfg

MYDB="mysql -u$myuser -p$mypass"

# Functions
kill_sleep_connections() {
    local host=$1
    local user=$2
    [[ -z $host ]] && echo "Usage: kill_sleep_connections <HOST NAME> [Specific user]" && return 1

    if [[ ! -z $user ]];then
            $MYDB -h$host -ANBe"show processlist" \
            | grep -w "$user" \
            | awk '{print $1}' \
            | while read id;do $MYDB -h$host -e"kill $id";done
    else
            $MYDB -h$host -ANBe"show processlist" \
            | grep Sleep \
            | awk '{print $1}' \
            | while read id;do $MYDB -h$host -e"kill $id";done
    fi
}

show_master_status() {

    [[ -z $1 ]] && echo "Error - Hostname is not provided" && return 1

    local host=$1
    local log_bin=`$MYDB -h$host -ANBe"select @@log_bin"`

    if [[ $log_bin -ne 1 ]];then
        echo "Binary logging is not enabled"
        return 0
    else
        $MYDB -h$host -e"show master status;"
    fi
}

show_slave_status() {

    [[ -z $1 ]] && echo "Error - Hostname is not provided" && return 1

    local host=$1
    local slave_running=`$MYDB -h$host -ANBe"show status like 'Slave_running'"`

    if [[ $slave_running == 'ON' ]];then
        $MYDB -h$host -e"show slave status\G" | egrep -w 'Master_Host|Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|' 
        return $?
    else
        echo "Not configured as a slave"
        return 1
    fi
}