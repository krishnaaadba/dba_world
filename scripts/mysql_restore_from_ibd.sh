#!/bin/bash
#
# Author     : Vamsi krishna
# Description: Script to restore a file directly from an .ibd file
# Assumptions: This script assumes the table already exists in the same database (so that it can pull the table's DDL)
#	       If the table is not there, the script won't help you. This will also only work with MariaDB, not MySQL or Percona

### Setting pipefail causes a failure return code if any command in the pipeline errors
set -o pipefail

# Define Functions
usage() {
        cat << EOF
Usage: ./$(basename $0) -d <DATABASE> -f <IBD FILE/S> [-o]

        Required:
	==========
	-d <DATABASE>
           The database you'll be restoring to
        -f <IBD FILE/S>
	   IMPORTANT: If you want to run this on multiple files, the files must be quoted!
           A comma separated list of .ibd files that you want to restore
	
	Optional:
	==========
	-o <OVERWRITE MODE>
	   Overwrites the tables in place (drop table then import)
	   Useful when you are tight on space
        -h --help <HELP>
           Display this usage

        Examples:
        ==========
        1) ./$(basename $0) -d my_db -f /some/dir/table.ibd
        2) ./$(basename $0) -d my_db -f "/some/dir/table_1.ibd, /some/dir/table_2.ibd" -o
EOF
exit 1
}

logger() {
        if [ ! -z $TABLE ]; then
                echo "[`date +'%Y-%m-%d %H:%M:%S'`] - $TABLE: $1"
        else
                echo "[`date +'%Y-%m-%d %H:%M:%S'`] - $1"
        fi
}

restore_table() {
	local TABLE TABLE_DDL TABLE_ROW_FORMAT TABLE_COPY IBD_FILE DEST_IBD_FILE DB_CONN

	IBD_FILE=$1
	DB_CONN="mysql -D $DB" # Rest each run with a frsh DB conn with schema name
	# Pull table name out of filename
	TABLE=$(echo $IBD_FILE | awk -F '/' '{print $NF}' | cut -f 1 -d '.')
	[[ $OVERWRITE_MODE -eq 0 ]] && TABLE_COPY="${TABLE}_ibd_restore"

	logger "Restore starting"
        if [ $OVERWRITE_MODE -eq 0 ]; then
                RESTORE_TABLE_EXISTS=$($DB_CONN -ANBe "SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('$TABLE', '$TABLE_COPY') AND table_schema = '$TEMP_DB'")
                [[ $RESTORE_TABLE_EXISTS -ge 1 ]] && logger "ERROR: One or more of the restore tables [$TABLE / $TABLE_COPY] already exists in schema [$TEMP_DB], please investigate! Skipping..." && return 1
        fi

	logger "Obtaining DDL"
	TABLE_DDL=$($DB_CONN -ANBe "show create table ${TABLE}\G" | tail -n +3)
	exit_check "Couldn't get DDL for $TABLE"
	TABLE_ROW_FORMAT=$($DB_CONN -ANBe "SELECT UPPER(ROW_FORMAT) FROM information_schema.tables WHERE table_name = '$TABLE' AND table_schema = '$DB'")
	exit_check "Couldn't get row_format information on $TABLE"

	# Update table DDL to include the row_format. If we are not overwriting the table, change the table name to <TABLE>_ibd_restore
	TABLE_DDL=$(echo -e "$TABLE_DDL\nROW_FORMAT=${TABLE_ROW_FORMAT};")

	if [ $OVERWRITE_MODE -eq 1 ]; then
		logger "WARN: Overwrite mode selected, so dropping $TABLE"
		$DB_CONN -Ae "DROP TABLE IF EXISTS $TABLE"
		exit_check "Couldn't drop $TABLE before creating a new version of it"
	fi

	DEST_IBD_FILE="${DATA_DIR}/${DB}/${TABLE}.ibd"

	# IF we aren't overwritting data, create table in temp schema
	[[ $OVERWRITE_MODE -eq 0 ]] && DB_CONN="mysql -D $TEMP_DB" && DEST_IBD_FILE="${DATA_DIR}/${TEMP_DB}/${TABLE}.ibd"

	logger "Creating table from DDL"
	$DB_CONN -Ae "$TABLE_DDL"
	exit_check "Couldn't create table by running DDL"

	logger "Discarding tablespace"
	$DB_CONN -Ae "ALTER TABLE $TABLE DISCARD TABLESPACE"
	exit_check "Couldn't discard the tablespace for $TABLE"

	logger "Copying the current .ibd file [$IBD_FILE] to [$DEST_IBD_FILE] (this could take a while for big tables)"
	# Using rysnc over cp so you can see progress
	rsync -ah --progress $IBD_FILE $DEST_IBD_FILE
	exit_check "Couldn't move .ibd file to $DEST_IBD_FILE"
	
	chown mysql:mysql $DEST_IBD_FILE

	logger "Importing tablespace (Ignore warnings, it's because we don't have a .cfg file, but that's OK)"
        $DB_CONN -vvv -Ae "ALTER TABLE $TABLE IMPORT TABLESPACE"
	exit_check "Couldn't import tablespace for $TABLE from .ibd file [$DEST_IBD_FILE]"

        if [ $OVERWRITE_MODE -eq 0 ]; then
                logger "Renaming table in temp schema"
                $DB_CONN -Ae "RENAME TABLE $TABLE TO $TABLE_COPY"
                exit_check "Couldn't rename [$TABLE] to [$TABLE_COPY]"
        fi

	logger "Restore successful!"
}	

### If the command line flag "--help" is used, display usage
if echo "$@" | grep -iq "\-\-help"; then
        usage
        exit 0
fi

### Set options
while getopts "d:f:oh" arg; do
        case "${arg}" in
		d) DB=${OPTARG};;
                f) IBD_FILES=$(echo ${OPTARG} | tr ",", " ");;
		o) OVERWRITE_MODE=1;;
                h) HELP=1;;
                *) usage;;
  	esac
done

### Variables: Static
TEMP_DB="test"

### Validation
[[ ! -z $HELP ]] && usage
[[ ! -f $DB_FUNCTIONS ]] && logger "ERROR - The function file [$DB_FUNCTIONS] does not exist, exiting!" && exit 1
source $DB_FUNCTIONS
[[ $(whoami) != "root" ]] && logger "ERROR - This script needs to be run as root (to move files and set permissions)" && exit 1
[[ -z $DB ]] || [[ -z $IBD_FILES ]] && logger "ERROR - Not all required options have been set" && usage
[[ -z "$OVERWRITE_MODE" ]] && OVERWRITE_MODE="0"

### Variables Computed
DB_CONN="mysql"
DATA_DIR=$($DB_CONN -ANBe "SHOW VARIABLES LIKE 'datadir'" | cut -f 2)
exit_check "Couldn't determine MySQL's data directory"

### Main Script
logger "Script started"

for ibd_file in $IBD_FILES; do
	[[ ! -f $ibd_file ]] && logger "ERROR - The file [$ibd_file] does not exist, skipping!" && continue
	restore_table $ibd_file
done

logger "Script finished"
exit 0