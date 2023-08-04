#!/bin/bash
#
# Author: Vamsi krishna
# Desc  : Grab the binlog co-ordinates from a server as set this host to be a slave to it

### Functions
usage() {
        cat << EOF
Usage: 
        -h <HOST>
           The remote host you want to connect to set up replication from (Master hostname)
EOF
exit 1
}

## Get options
while getopts "h:" arg; do
        case "$arg" in
                h) REMOTE_HOST="${OPTARG}";;
                *) usage;;
        esac
        allargs+=$OPTARG
done

### Dependancies
MYCNF="~/.my.cnf"

if [ ! -f $MYCNF ]; then
        echo "Cannot find the file my.cnf at [$MYCNF]. Exiting..." 
        exit 1
fi

log "Script started"
### Main Variables
DB_USER=$(my_print_defaults mysql --defaults-file=$MYCNF | grep -- ^--user     | cut -f 2 -d '=')
DB_PASS=$(my_print_defaults mysql --defaults-file=$MYCNF | grep -- ^--password | cut -f 2 -d '=')
DB_SLAVE_USER=$(my_print_defaults clientslave --defaults-file=$MYCNF | grep -- ^--user     | cut -f 2 -d '=')
DB_SLAVE_PASS=$(my_print_defaults clientslave --defaults-file=$MYCNF | grep -- ^--password | cut -f 2 -d '=')
LOCAL_HOST=$(hostname -s)
LOCAL_IP=$(host $LOCAL_HOST | awk '{print $NF}')
REMOTE_IP=$(host $REMOTE_HOST | awk '{print $NF}')
REMOTE_CONN="mysql -u $DB_USER -p$DB_PASS -h $REMOTE_HOST"
LOCAL_CONN="mysql -u $DB_USER -p$DB_PASS"

### Validation
log "Running from $LOCAL_HOST"
log "Running initial validation checks"
[[ "$(whoami)" != "mysql" ]] && log "ERROR - This needs to be run as the mysql user. Exiting!" && exit 1
[[ -z "$DB_USER" ]] || [[ -z "$DB_PASS" ]] && log "ERROR - User and/or Password from the command [my_print_defaults mysql] is empty. Exiting..." && exit 1
[[ -z "$DB_SLAVE_USER" ]] || [[ -z "$DB_SLAVE_PASS" ]] && log "ERROR - User and/or Password from the command [my_print_defaults clientslave] is empty. Exiting..." && exit 1

[[ "$LOCAL_IP" == "$REMOTE_IP" ]] && log "ERROR - It seems you are trying to set up replication to the same machine! Exiting!" && usage && exit 1
[[ -z $LOCAL_IP ]] || [[ -z $REMOTE_IP ]] && log "ERROR - Could not pull a IP information for $REMOTE_HOST or $LOCAL_HOST. Exiting!" && exit 1

LOCAL_SLAVE_STATUS=$($LOCAL_CONN -Ae "show slave status\G" | grep -i running | grep -ic yes)
exit_check "Couldn't connect to MySQL to pull slave status information from $LOCAL_HOST"
[[ $LOCAL_SLAVE_STATUS -gt 0 ]] && log "ERROR - A running slave appears to be already running on $LOCAL_HOST. Exiting!" && exit 1

# Pull the datadir from MySQL directly in case it hasn't been set in the my.cnf
DATA_DIR=$($LOCAL_CONN -ANBe "show variables like 'datadir'" | cut -f 2)
exit_check "Couldn't pull the datadir from MySQL on $LOCAL_HOST"
[[ -f ${DATA_DIR}/master.info ]] && log "INFO - The master.info file exists in ${DATA_DIR}. We can safely assume replication has already been set up, even if it's not currently running" && exit 0

REMOTE_DBS=$($REMOTE_CONN -ANBe "show databases")
exit_check "Couldn't connect to MySQL to pull database information from $REMOTE_HOST"
LOCAL_DBS=$($LOCAL_CONN -ANBe "show databases")
exit_check "Couldn't connect to MySQL to pull database information from $LOCAL_HOST"

[[ -z $REMOTE_DBS ]] || [[ -z $LOCAL_DBS ]] && log "ERROR - Could not pull a database list from $REMOTE_HOST or $LOCAL_HOST. Exiting!" && exit 1

for db in $REMOTE_DBS; do
	IS_MATCH=$(echo $LOCAL_DBS | grep -wic $db)
	[[ $IS_MATCH -ne 1 ]] && log "ERROR - The database [$db] does not exist on both $REMOTE_HOST and $LOCAL_HOST. Exiting!" && exit 1
done

log "Databases between $REMOTE_HOST and $LOCAL_HOST match"

REMOTE_TABLE_COUNT=$($REMOTE_CONN -ANBe "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('mysql','information_schema')")
exit_check "Couldn't connect to MySQL to pull table information from $REMOTE_HOST"
LOCAL_TABLE_COUNT=$($LOCAL_CONN -ANBe "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('mysql','information_schema')")
exit_check "Couldn't connect to MySQL to pull table information from $LOCAL_HOST"

[[ -z $REMOTE_TABLE_COUNT ]] || [[ -z $LOCAL_TABLE_COUNT ]] && log "ERROR - Could not pull a table counts from $REMOTE_HOST or $LOCAL_HOST. Exiting!" && exit 1
[[ $REMOTE_TABLE_COUNT -ne $LOCAL_TABLE_COUNT ]] && log "ERROR - The table count between $REMOTE_HOST [$REMOTE_TABLE_COUNT] and $LOCAL_HOST [$LOCAL_TABLE_COUNT] do not match! Exiting!" && exit 1

log "The table count between $REMOTE_HOST [$REMOTE_TABLE_COUNT] and $LOCAL_HOST [$LOCAL_TABLE_COUNT] match"

SLAVE_USER_EXISTS=$($REMOTE_CONN -ANBe "SELECT COUNT(*) FROM mysql.user WHERE user = 'slave' AND host like '10%'")
exit_check "Couldn't connect to MySQL to pull slave user information"
[[ $SLAVE_USER_EXISTS -eq 0 ]] && log "ERROR - The slave user is needed for replication but does not exist on $REMOTE_HOST. Exiting!" && exit 1

### Main Script
log "All validation checks have passed. Setting up $LOCAL_HOST as a slave off $REMOTE_HOST"

MASTER_BINLOG_INFO=$($REMOTE_CONN -ANBe "show master status")
exit_check "Couldn't connect to MySQL to pull the binlog position on $REMOTE_HOST"
MASTER_BINLOG_FILE=$(echo "$MASTER_BINLOG_INFO" | cut -f 1)
MASTER_BINLOG_POS=$(echo "$MASTER_BINLOG_INFO" | cut -f 2)

log "Binlog info for $REMOTE_HOST. File = $MASTER_BINLOG_FILE // Position = $MASTER_BINLOG_POS"
log "Running SQL on $LOCAL_HOST - [CHANGE MASTER TO MASTER_HOST = '$REMOTE_HOST', MASTER_USER = '$DB_SLAVE_USER', MASTER_PASSWORD = '****', MASTER_LOG_FILE = '$MASTER_BINLOG_FILE', MASTER_LOG_POS = $MASTER_BINLOG_POS]"

$LOCAL_CONN -Ae "CHANGE MASTER TO MASTER_HOST = '$REMOTE_HOST', MASTER_USER = '$DB_SLAVE_USER', MASTER_PASSWORD = '$DB_SLAVE_PASS', MASTER_LOG_FILE = '$MASTER_BINLOG_FILE', MASTER_LOG_POS = $MASTER_BINLOG_POS"
exit_check "Couldn't connect to MySQL to set up $LOCAL_HOST as a slave off $REMOTE_HOST"

$LOCAL_CONN -Ae "start slave"
exit_check "Couldn't connect to MySQL on $LOCAL_HOST to start replication"

log "Replication started, validating whether it's running"
LOCAL_SLAVE_STATUS=$($LOCAL_CONN -Ae "show slave status\G" | grep -i running | grep -ic yes)
exit_check "Couldn't connect to MySQL to pull slave status information from $LOCAL_HOST"
[[ $LOCAL_SLAVE_STATUS -ne 2 ]] && log "ERROR - The slave on $LOCAL_HOST does not appear to be running, manual investigation is needed. Exiting!" && exit 1

log "Success! $LOCAL_HOST has successfully been setup as a slave off $REMOTE_HOST"
log "Script finished"
exit 0