#!/bin/bash
#
# Author: Vamsi krishna
# Desc  : This script creates after insert/update/delete triggers statements for a table


usage() {
cat << EOF

	Required:
	==========
		-H Hostname where the table is
		-t Table name
		-D Database name
		-u username
		-p password

	Optional:
	==========
		-h Prints this helper message

	Example:
	==========
		./$(basename $0) -tfoo -Dbar -Hfoohost -uusername -ppassword

EOF

exit 1
}

exit_check() {
	local ret_val=$?
	local msg=$1

	if [[ $ret_val -ne 0 ]];then
		echo "Error - $msg"
		exit 1
	fi
}

is_valid_hostname() {
  local hostname=$1
  ping -c 1 "$hostname" >/dev/null 2>&1
  return $?
}


# Gather input parameters
while getopts "t:D:H:u:p:h" arg;do
	case $arg in
		t) TABLE=${OPTARG};;
		D) DB=${OPTARG};;
		H) HOST=${OPTARG};;
		u) USER=${OPTARG};;
		p) PASS=${OPTARG};;
		h) usage ;;
		*) usage ;;
	esac
done

#Variables computed
DBCONN="mysql -u$USER -p$PASS -h$HOST -D$DB"


# Validations
[[ -z $TABLE || -z $DB || -z $HOST || -z $USER || -z $PASS ]] && usage
is_valid_hostname "$HOST"
exit_check "[$HOST] is not a valid host/unreachable. Please check and try again."
DB_VALID=`$DBCONN -ANBe"select count(*) from information_schema.schemata where SCHEMA_NAME='$DB'"`
exit_check "Could not validate $DB existence"
TABLE_VALID=`$DBCONN -ANBe"select count(*) from information_schema.tables where table_schema='$DB' and table_name='$TABLE'"`
exit_check "Could not validate $TABLE's existence"
[[ $DB_VALID -ne 1 || $TABLE_VALID -ne 1 ]] && echo "Error - Either of $DB/$TABLE are not valid parameters" && exit 1


#Gather primary key columns
PK_COLS=`$DBCONN -ANBe"select COLUMN_NAME from information_schema.columns where TABLE_SCHEMA='$DB' and TABLE_NAME='$TABLE' and COLUMN_KEY='PRI';"`
exit_check "Got error obtaining PK columns. Exiting..."

if [[ -z $PK_COLS ]];then
	echo "No primary key found for table. Exiting..."
	exit 1
fi

#Gather columns
OLD_COLS=`$DBCONN -ANBe"select group_concat(COLUMN_NAME) from information_schema.columns where TABLE_SCHEMA='$DB' and TABLE_NAME='$TABLE' order by ORDINAL_POSITION;"`
exit_check "Could not obtain column names from the table"
NEW_COLS=`$DBCONN -ANBe"select group_concat(concat('NEW.',COLUMN_NAME)) from information_schema.columns where TABLE_SCHEMA='$DB' and TABLE_NAME='$TABLE' order by ORDINAL_POSITION;"`
exit_check "Could not generate column names from the table"


for col in $PK_COLS;do
	DEL_NOT_CLAUSE="OLD.$col <=> NEW.$col , $DEL_NOT_CLAUSE"
	DEL_CLAUSE="$DB._${TABLE}_new.$col <=> OLD.$col , $DEL_CLAUSE"
done

DEL_NOT_CLAUSE=`echo $DEL_NOT_CLAUSE | sed 's/.$//' | sed 's/,/and/g'`
DEL_CLAUSE=`echo $DEL_CLAUSE | sed 's/.$//' | sed 's/,/and/g'`

# DO NOT forget to create the new table
echo "######### Create New Table #########"
echo -ne "create table $DB._${TABLE}_new like $DB.${TABLE};"
echo -ne "\n\n"

# AFTER INSERT Trigger
echo "######### AFTER INSERT TRIGGER ########"
echo -ne "DELIMITER //\nCREATE TRIGGER ${TABLE}_ins\nAFTER INSERT ON ${TABLE}\nFOR EACH ROW\nBEGIN\n"
echo -ne "REPLACE INTO $DB._${TABLE}_new ($OLD_COLS) VALUES ($NEW_COLS);\n"
echo -ne "END; //\nDELIMITER ;\n"
echo -ne "\n\n"

# AFTER UPDATE Trigger
echo "######### AFTER UPDATE TRIGGER ########"
echo -ne "DELIMITER //\nCREATE TRIGGER ${TABLE}_upd\nAFTER UPDATE ON ${TABLE}\nFOR EACH ROW\nBEGIN\n"
echo -ne "DELETE IGNORE FROM $DB._${TABLE}_new WHERE !($DEL_NOT_CLAUSE) AND $DEL_CLAUSE; REPLACE INTO $DB._${TABLE}_new ($OLD_COLS) values ($NEW_COLS);\n"
echo -ne "END; //\nDELIMITER ;\n"
echo -ne "\n\n"

# AFTER DELETE Trigger
echo "######### AFTER DELETE TRIGGER ########"
echo -ne "DELIMITER //\nCREATE TRIGGER ${TABLE}_del\nAFTER DELETE ON ${TABLE}\nFOR EACH ROW\nBEGIN\n"
echo -ne "DELETE IGNORE FROM $DB._${TABLE}_new WHERE $DEL_CLAUSE;\n"
echo -ne "END; //\nDELIMITER ;\n"

exit 0