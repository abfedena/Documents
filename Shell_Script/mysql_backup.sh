#!/bin/bash

EMAIL_ADDRESSES='sankar.h.patel@gmail.com'
db_backup_dir="/opt/backup"
DAY_HOUR=`date +%a_%H`
DAY_BEFORE_7DAY=`date +%d-%m-%Y --date="7 day ago"`
NOW=`date +%d-%m-%H-%M`

DB_BKP=1
DB_UPLOAD=1
> /tmp/backup.log
DB_NAME="prod_apr_17"
DB_USER="adviser"
DB_PASSWD="Adviser"
MYSQL_OPTS="-u $DB_USER -p$DB_PASSWD"
## If want to upload in s3
S3BUCKET_NAME="s3://dbbackup-punditas"
BUCKET_PATH="Punditas"

FAILED_BKP_LIST=""


echo -e "##################################         BACKUP STATUS     ##################################" >> /tmp/backup.log
echo "###############################################################################################" >> /tmp/backup.log
echo -e "\n\t\t\tDatabase Backup script execution log " >> /tmp/backup.log
echo "###############################################################################################" >> /tmp/backup.log





function BACKUP()
{

    if [ ! -d $db_backup_dir ]
    then
        /bin/mkdir -p $db_backup_dir
    fi
    cd $db_backup_dir
    #DB_LIST=`mysql $MYSQL_OPTS -e'show databases;'| grep -v mysql$  | grep -v Database$ | grep -v information_schema$ | grep -v test$`
    DB_LIST="$DB_NAME"
    for DB_NAME in $(echo $DB_LIST)
    do
        /usr/bin/mysqldump $MYSQL_OPTS $DB_NAME | bzip2 > $db_backup_dir/$DB_NAME\_$NOW.sql.bz2
            if [ $? -ne 0 ]
            then
                FAILED_BKP_LIST="$FAILED_BKP_LIST $DB_NAME"
            fi
    done

    if [ "$FAILED_BKP_LIST" == "" ]
    then
            DB_BKP=0
        echo "List of Files to be removed " >> /tmp/backup.log
        find $db_backup_dir -mmin +7200 -type f -print0 | xargs -0 /bin/rm
        echo "">> /tmp/backup.log ; echo "" >> /tmp/backup.log
    fi

}

function S3_UPLOAD()
{
    #if [ $DB_BKP == 0 ]
    #then
    #   echo -e "Backup Succesfully taken. \nNow Uploading to s3bucket." >> /tmp/backup.log
    #   #s3cmd sync --delete-removed  /backup_mysql/ s3://dbbackup-punditas/Punditas/ 2>&1  >> /tmp/backup.log && DB_UPLOAD=0 
    #   s3cmd sync --delete-removed  $db_backup_dir $S3BUCKET_NAME/$BUCKET_PATH/ 2>&1  >> /tmp/backup.log && DB_UPLOAD=0
    #   echo 3 >/proc/sys/vm/drop_caches
    #fi
}


function NOTIFY()
{
    if [ $DB_BKP -ne 0 ]  # || [ $DB_UPLOAD -ne 0 ]
    then
        test $DB_BKP -ne 0 && FAILED_LIST="Database Backup, "$FAILED_LIST
        test $DB_UPLOAD -ne 0 && FAILED_LIST="Database Upload on s3, "$FAILED_LIST
        sed -i "2i#\\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ $FAILED_LIST Process(es) Failed." /tmp/backup.log
        mail -s "UserAdvisor_DB: $NOW-00 backup failed." $EMAIL_ADDRESSES < /tmp/backup.log
        echo CRITICAL > /tmp/backup_status
        exit 2
    else
        sed -i "2i#\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ All Process for Backup successfully executed"  /tmp/backup.log
        mail -s "UserAdvisor_DB: $NOW-00 Backup successfully taken." $EMAIL_ADDRESSES < /tmp/backup.log
        echo OK > /tmp/backup_status
            exit 0
    Files
}

BACKUP
S3_UPLOAD
NOTIFY