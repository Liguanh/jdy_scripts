#!/bin/sh
#desc : every 2 hours full backup jdy databases
#date : 2016-09-21
#author : zhang.shuang@9douyu.com

Path_backup='/backup/9douyu.com/database'
Path_dump='/opt/lampp/bin/mysqldump'

#Date
file_name=`date +%Y%m%d%H%M`
ErrorLog="/tmp/backup_database_error.log"

#parameter
checkrun()
{

result="$?"

if [ $result -eq 0 ]
then
  :
else
  echo "Error $1 has happened at $file_name" >> $ErrorLog
  exit 10
fi
}

#del old file
find $Path_backup -name "*.zip" -a -mtime +30 -exec rm {} -f \;
checkrun find_rm_1

$Path_dump   --add-drop-table -ubackup_user -pB6DdeQ9DeWVGE3k -hrr-2zeap9jp480wx4j12.mysql.rds.aliyuncs.com --set-gtid-purged=OFF jiudouyu_core_db > $Path_backup/jiudouyu_core_db_$file_name.sql
$Path_dump   --add-drop-table -ubackup_user -pB6DdeQ9DeWVGE3k -hrr-2zeap9jp480wx4j12.mysql.rds.aliyuncs.com --ignore-table=jiudouyu_module_db.module_credit_merge --set-gtid-purged=OFF jiudouyu_module_db > $Path_backup/jiudouyu_module_db_$file_name.sql
$Path_dump   --add-drop-table -ubackup_user -pB6DdeQ9DeWVGE3k -hrr-2zeap9jp480wx4j12.mysql.rds.aliyuncs.com --set-gtid-purged=OFF jiudouyu_service_db > $Path_backup/jiudouyu_service_db_$file_name.sql

checkrun mysqldump


cd $Path_backup/
zip jiudouyu_core_db_$file_name.sql.zip jiudouyu_core_db_$file_name.sql
zip jiudouyu_module_db_$file_name.sql.zip jiudouyu_module_db_$file_name.sql
zip jiudouyu_service_db_$file_name.sql.zip jiudouyu_service_db_$file_name.sql
checkrun zip


rm -f jiudouyu_core_db_$file_name.sql
rm -f jiudouyu_module_db_$file_name.sql
rm -f jiudouyu_service_db_$file_name.sql

file_name2=`date +%Y%m%d%H%M`
echo $file_name2 > /tmp/backup_end_time.txt
