#!/bin/sh

if [ "$#" -ne 5 ]
then
        echo "Please provide all necessary argument to restart $4 service!! "
        exit 3
fi

HOSTADDRESS=$4
function service_status()
{
	/usr/local/nagios/libexec/plugins/check_nrpe -H $HOSTADDRESS -c $1 -a $2	
}
service_status_iis=`service_status service_status iisadmin`
service_status_w3svc=`service_status service_status w3svc`

case "$1" in
        OK)
                ;;
        WARNING)
                ;;
        UNKNOWN)
                ;;
        CRITICAL)
                case "$2" in
                        SOFT)
                                case "$3" in
                                        1)
						echo "1st Soft State...."
                                                ;;
                                        2)
						echo "1st Soft State...."
                                                ;;
                                esac ;;
                        HARD)
                                if [ "$service_status_w3svc" != "RUNNING" ]
                                then
                                	if [ "$service_status_iis" != "RUNNING" ]
                                        then
                                        	service_status service_start iisadmin && service_status service_start w3svc
                                        else
                                                service_status service_start w3svc
                                        fi
                                fi
                                ;;
                esac
        ;;
esac
exit 0
