#!/bin/bash
#
# Author : Vamsi Krishna
# Desc   : This script calculates the table size from information_schema


### Set pipefail ###
# Setting pipefail causes a failure return code if any command in the pipeline errors
set -o pipefail

### Functions
usage() {
cat << EOF

Usage:
	Required:
	==========
        -H Hostname
        -D Database name

        Optional:
        ==========
        -t Table name 
        -h --help <HELP>
           Display this usage

        Example:
        ==========
        - Lists table sizes of all tables in employees database
        	$(basename $0) -Hdb-server-01 -Demployees

        - List table size of salary from employees database
        	$(basename $0) -Hdb-server-01 -Demployees -tsalary
EOF
}

log() {
        echo "[`date +'%Y-%m-%d %H:%M:%S'`]: $1"
}

### If the command line flag "--help" is used, display usage
if echo "$@" | grep -iq "\-\-help"; then
        usage
        exit 0
fi

### Get options
while getopts "H:D:t:h" arg; do
        case "$arg" in
                H) HOST="${OPTARG}";;
		D) DB="${OPTARG}";;
		t) TABLES="${OPTARG}";;
                h) HELP=1;;
                *) usage;;
        esac
done

### Pre-Steps
[[ ! -z "${HELP}" ]] && usage && exit 0

log "Starting up `basename $0`"

### Variables: Static
MY_CNF="~/.my.cnf"
DB_CONN="mysql -u$myuser -p$mypass -h $host"

### Validation
[[ -z $HOST || -z $DB ]] && log "ERROR - No host/database name were specified" && usage && exit 1
[[ -z $myuser || -z $mypass ]] && log "ERROR - Login credentials are unset" && exit 1

### Main Script

if [[ ! -z $TABLES ]];then
	# Converting csv TABLES variable to MySQL compliant in clause
	# Converting from table1,table2,table3 to 'table1','table2','table3'
	TABLES=`echo $TABLES | sed -e "s/$/'/g" -e "s/^/'/g" -e "s/,/','/g"`

	SQL="SELECT SUBSTRING_INDEX(@@hostname, '.', 1) AS 'host', table_schema, table_name, IFNULL(ROUND(SUM(data_length + index_length) / 1024 /  1024, 2),0) AS 'MB', CURDATE() 
		FROM information_schema.tables 
		WHERE table_schema IN ('$DB') 
		GROUP BY host, table_name
		having table_name in ($TABLES);"
else
	SQL="SELECT SUBSTRING_INDEX(@@hostname, '.', 1) AS 'host', table_schema, table_name, IFNULL(ROUND(SUM(data_length + index_length) / 1024 /  1024, 2),0) AS 'MB', CURDATE() 
		FROM information_schema.tables 
		WHERE table_schema IN ('$DB') 
		GROUP BY host, table_name;"
fi


$DB_CONN -e"$SQL"
exit $?