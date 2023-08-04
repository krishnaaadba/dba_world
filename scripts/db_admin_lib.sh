#!/bin/bash
#
# Author: Vamsi krishna
# Desc  : This is a library of functions for mysql administration


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

