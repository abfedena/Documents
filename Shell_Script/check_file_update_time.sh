#!/bin/bash
#####
#The script will check the last updated time of file and if the file was not updated in last one minut it will shows critical
#
#Created by Shankar Patel- Compufy Technolab
#Create date : 10-10-2012
#Deploy date : 10-10-2012
################################################################################

function help {
        echo "
The plugin is used to check any file since when not updated.
        Usage:
                $0 -f <Name of File> -t <Minutes>
        Option:
                f - File name whihc you want to check is updated or not.
                t - Time in minute since not updated
                m - Service name as a output message to view in alert.
		s - String if you want to check in file 
                h - Help.
        Example:
                $0 -f /var/log/syslog -t 5
                CRITICAL: /var/log/secure file not updated From , current time is 11:20| active=0
        "
        exit 3;
}


while getopts "f:t:m:s:h" OPT; do
        case $OPT in
                "f") file_name=$OPTARG;;
                "t") crit_time=$OPTARG;;
                "m") msg=$OPTARG;;
		"s") search_string=$OPTARG;;
                "h") help;;
        esac
done


if [ "$file_name" = "" ] || [ "$crit_time" = "" ] || [ "$search_string" == "" ] ; then  help ; fi

if [ $(ls $file_name >/dev/null ;echo $?) -eq 0 ]
then
        file_path=`echo $file_name | awk -F "$(basename $file_name)" '{print $1}'`
        lst_update_time=`stat $file_name | grep -i modify | awk '{print $3":"$2}' | awk -F':' '{print $1":"$2" "$4}'`
        file_ok_name=`find $file_path -mmin -$crit_time | grep $file_name$`
	file_content=`grep -i $search_string $file_name | wc -l`
        if [ "$file_ok_name" = "$file_name" ] && [ $file_content -eq 0 ]
        then
		if [ "$msg" = "" ] 
		then
               		 echo "OK. $file_name file is updated on $lst_update_time. | active=1"
		else 
               		 echo "OK. $msg service is running fine. | active=1"
		fi
                exit 0;
        else
		if [ "$msg" = "" ] 
		then
                        echo "CRITICAL. $file_name file not updated From $lst_update_time, current time is $(date +%H:%M)| active=0"
		else
            		echo "CRITICAL. $msg service seems not running From $lst_update_time,  current time is $(date +%H:%M) | active=0"
		fi
                exit 2;
        fi
else
        echo "UNKNOWN. File doesnot exist."
        exit 3;
fi

