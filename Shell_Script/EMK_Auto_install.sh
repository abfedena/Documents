#!/bin/sh 
############################################################################################
############################################################################################
##   DESCRIPTION : ICINGA SERVER INSTALLATION SCRIPT   			  ##########################
##   AUTHOR	     : Shankar Patel 				  				  ##########################
##   Role  	     : EMS Administrator							  ##########################
##   COMPANY  	 : EFFONE										  ##########################
##	 CHANGE LOG  : Added SVN commit to save configs in repository ##########################
##   Version	 : 1.2	                                          ##########################
############################################################################################
############################################################################################

function PRINTLOGO() 
{
	echo -e "\t\tEEEEEE FFFFFF FFFFFF   OOOO   NN   NN EEEEEE\n\t\tEE     FF     FF     OO    OO NNN  NN EE\n\t\tEEEEE  FFFFF  FFFFF  OO    OO NN N NN EEEEE\n\t\tEE     FF     FF     OO    OO NN  NNN EE\n\t\tEEEEEE FF     FF       OOOO   NN   NN EEEEEE"
}

#Checks current user is root or not
if [ "$(whoami)" != "root" ] 
then
	echo "^!^ You are not root user..!!! \nPlease execute as user root."
fi

##################
#  FUNCTIONS INITIALIZATION 
##################


#if there is something wrong with the command line option it will display below function.
#It explains how to install icinga server using this script
function USAGE
{
        echo -e "Basic Usage: \n\t$0 -d <FQDN> -l <ServerLocation City/Area name> -n <MY NETWORK RANGE>"
        echo -e "\nOptions:\n\td - Provide the FQDN like effone.com\n\tn - Your private network range like: 192.168.2.0/24 \n\tl - Geographical location of Monitoring Server (Country OR State OR City OR locality)\n\te - SystemAdministrators E-MAILID (its optional, default will be EFFONE Admins) \n\tm - Mysql Database Server host address (its optional, default is localhost ) \n\tu - Mysql database full privileged username if mysql is already installed (Default is root)\n\tp - Mysql user password if already set password for given user "
        echo -e "Example:-\n\t$0 -d effone.com -n 192.168.2.0/24 -l Bangalore"
}




function CREATEICINGACONFIGS()
{
	CHECKMYSQLINSTALLED
	# Creating lconf structure for icinga configuration
	mkdir -p /etc/icinga/lconf/contacts /etc/icinga/lconf/contactgroups /etc/icinga/lconf/commands /etc/icinga/lconf/servicegroups /etc/icinga/lconf/timeperiod /etc/icinga/lconf/hostgroups/ /etc/icinga/lconf/icinga_$Domain /etc/icinga/lconf/icinga_$Domain/Servers /etc/icinga/lconf/icinga_$Domain/Infrastracture
	echo -e "\ndefine contact { \n\tuse generic-contact \n\tservice_notifications_enabled    1 \n\tservice_notification_options u,r \n contact_name `echo $ADMINEMAILID | cut -d'@' -f1` \n email   $ADMINEMAILID \n host_notification_options  d,u,r \n     host_notifications_enabled 1 \n alias $(echo $ADMINEMAILID | cut -d'@' -f1) \n}" >/etc/icinga/lconf/contacts/`echo $ADMINEMAILID | cut -d'@' -f1`.cfg
	echo -e '\ndefine host { \n\tuse generic-host \n\thost_name ICINGA_EFFONE \n\tactive_checks_enabled 1 \n\tnotifications_enabled     0 \n\tcheck_interval 5 \n\t freshness_threshold  1 \n\thostgroups EMS-CORPORATION \n\tprocess_perf_data 1 \n\tretry_interval  1 \n\tmax_check_attempts      3\n\tnotification_period 24x7 \n\tnotification_options d,u,r \n\taddress 127.0.0.1 \n\tnotification_interval    15 \n\tcontact_groups EMS_Admin \n\tcheck_command  check-host-alive \n\talias    ICINGA_EFFONE_LINUX \n}'  | sed "s/ICINGA_EFFONE/ICINGA_$DOMAIN/g" | sed "s/EMS-CORPORATION/$DOMAIN/g" >/etc/icinga/lconf/icinga_$Domain/Servers/ICINGA_$DOMAIN.cfg
	echo -e "$SERVICELIST" > svclist && cat svclist | while read SERVICE COMMAND
	do
		echo -e  "\ndefine service {\n\tuse generic-service \n\tservice_description   $SERVICE\n\thost_name ICINGA_EFFONE \n\tcheck_freshness 1 \n\tactive_checks_enabled 1 \n\tcontact_groups EMS_Admin \n\tcheck_command   $COMMAND \n\tnotifications_enabled  0 \n\tcheck_period 24x7 \n\tretry_interval   1 \n\tmax_check_attempts      3\n\tpassive_checks_enabled 0 \n\tflap_detection_enabled 1 \n\tnotification_options w,u,c,r \n\tcheck_interval 5 \n\tprocess_perf_data 1 \n\tnotification_interval 15 \n\tnotification_period 24x7 \n}\n " | sed "s/ICINGA_EFFONE/ICINGA_$DOMAIN/g" | sed "s/EMS-CORPORATION/$DOMAIN/g" >>/etc/icinga/lconf/icinga_$Domain/Servers/ICINGA_$DOMAIN.cfg
	done
	rm svclist
	echo -e '\ndefine command { \n command_name icinga_status \n     command_line /usr/local/nagios/libexec/plugins/check_nagiostats.pl -s overview -c /etc/icinga/icinga.cfg  -n /usr/bin/nagiostats \n}' > /etc/icinga/lconf/commands/icinga_status.cfg
	echo -e '\ndefine command { \n command_name check-host-alive \n  command_line /usr/local/nagios/libexec/plugins/check_ping -H $HOSTADDRESS$ -w 3000.0,80% -c 5000.0,100% -p 5 \n}' >/etc/icinga/lconf/commands/check-host-alive.cfg
	echo -e '\ndefine command { \n command_name process-service-perfdata \n  command_line  /usr/bin/printf "%b" "$LASTSERVICECHECK$\\t$HOSTNAME$\\t$SERVICEDESC$\\t$SERVICESTATE$\\t$SERVICEATTEMPT$\\t$SERVICESTATETYPE$\\t$SERVICEEXECUTIONTIME$\\t$SERVICELATENCY$\\t$SERVICEOUTPUT$\\t$SERVICEPERFDATA$\\n" >> /var/lib/icinga-perfdata/service-perfdata.out \n}' >/etc/icinga/lconf/commands/process-service-perfdata.cfg
	echo -e '\ndefine command { \n command_name check_smtp \n  command_line  /usr/local/nagios/libexec/plugins/check_smtp -H $HOSTADDRESS$ \n}' >/etc/icinga/lconf/commands/check_smtp.cfg
	echo -e '\ndefine command { \n command_name notify-host-by-email \n  command_line      /usr/bin/printf "%b" "***** ICINGA *****\\n\\nNotification Type: $NOTIFICATIONTYPE$\\nHost: $HOSTNAME$\\nState: $HOSTSTATE$\\nAddress: $HOSTADDRESS$\\nInfo: $HOSTOUTPUT$\\n\\nDate/Time: $LONGDATETIME$\\n" | /bin/mail -s "** $NOTIFICATIONTYPE$ Host Alert: $HOSTNAME$ is $HOSTSTATE$ **" $CONTACTEMAIL$ \n}' >/etc/icinga/lconf/commands/notify-host-by-email.cfg
	echo -e '\ndefine command { \n command_name check_tcp \n command_line /usr/local/nagios/libexec/plugins/check_tcp -H $HOSTADDRESS$ -p $ARG1$ -w $ARG2$ -c $ARG3$ \n}' >/etc/icinga/lconf/commands/check_tcp.cfg
	echo -e '\ndefine command { \n command_name check_snmp \n  command_line  /usr/local/nagios/libexec/plugins/check_snmp -H $HOSTADDRESS$ $ARG1$ \n}' >/etc/icinga/lconf/commands/check_snmp.cfg
	echo -e '\ndefine command { \n command_name check_nrpe \n  command_line  /usr/local/nagios/libexec/plugins/check_nrpe -H $HOSTADDRESS$ -c $ARG1$ \n}' >/etc/icinga/lconf/commands/check_nrpe.cfg
	echo -e '\ndefine command { \n command_name check_nrpe1 \n command_line  /usr/local/nagios/libexec/plugins/check_nrpe -H $HOSTADDRESS$ -c $ARG1$ -a $ARG2$ \n}' >/etc/icinga/lconf/commands/check_nrpe1.cfg
	echo -e '\ndefine command { \n command_name check_ssh \n command_line /usr/local/nagios/libexec/plugins/check_ssh -H $HOSTADDRESS$ -t 20 \n}' >/etc/icinga/lconf/commands/check_ssh.cfg
	echo -e '\ndefine command { \n command_name notify-service-by-email \n   command_line  /usr/bin/printf "%b" "***** ICINGA *****\\n\\nNotification Type: $NOTIFICATIONTYPE$\\n\\nService: $SERVICEDESC$\\nHost: $HOSTALIAS$\\nAddress: $HOSTADDRESS$\\nState: $SERVICESTATE$\\n\\nDate/Time: $LONGDATETIME$\\n\\nAdditional Info:\\n\\n$SERVICEOUTPUT$\\n" | /bin/mail -s "** $NOTIFICATIONTYPE$ Service Alert: $HOSTALIAS$/$SERVICEDESC$ is $SERVICESTATE$ **" $CONTACTEMAIL$ \n}' >/etc/icinga/lconf/commands/notify-service-by-email.cfg
	echo -e "\ndefine command { \n command_name check_mysql_perm \n command_line  /usr/local/nagios/libexec/plugins/check_mysql -H $DB_HOST -u \$ARG1\$ -p \$ARG2\$ -d \$ARG3\$ \n}" >/etc/icinga/lconf/commands/check_mysql_perm.cfg
	echo -e "\ndefine command { \n command_name check_mysql \n command_line  /usr/local/nagios/libexec/plugins/check_mysql_health $CHECK_MYSQL_CREDENTIALS --mode \$ARG1\$ \n}" >/etc/icinga/lconf/commands/check_mysql.cfg
	echo -e '\ndefine command { \n command_name process-host-perfdata \n command_line      /usr/bin/printf "%b" "$LASTHOSTCHECK$\\t$HOSTNAME$\\t$HOSTSTATE$\\t$HOSTATTEMPT$\\t$HOSTSTATETYPE$\\t$HOSTEXECUTIONTIME$\\t$HOSTOUTPUT$\\t$HOSTPERFDATA$" >> /var/lib/icinga-perfdata/host-perfdata.out \n}' >/etc/icinga/lconf/commands/process-host-perfdata.cfg
	echo -e '\ndefine command { \n command_name process-service-perfdata-file \n  command_line /bin/mv /var/lib/icinga-perfdata/service-perfdata /var/lib/icinga-perfdata/service-perfdata.$TIMET$ \n}' >/etc/icinga/lconf/commands/process-service-perfdata-file.cfg
	echo -e '\ndefine command { \n command_name check_nt \n command_line /usr/local/nagios/libexec/plugins/check_nt -p 12489 -H $HOSTADDRESS$ -v $ARG1$ \n}' >/etc/icinga/lconf/commands/check_nt.cfg
	echo -e '\ndefine command { \n command_name process-host-perfdata-file \n  command_line /bin/mv /var/lib/icinga-perfdata/host-perfdata /var/lib/icinga-perfdata/host-perfdata.$TIMET$ \n}'  >/etc/icinga/lconf/commands/process-host-perfdata-file.cfg
	echo -e '\n############################################################################### \n# TEMPLATES.CFG - SAMPLE OBJECT TEMPLATES \n# \n# Last Modified: 10-03-2007 \n# \n# NOTES: This config file provides you with some example object definition \n#        templates that are refered by other host, service, contact, etc. \n#        definitions in other config files. \n#        \n#        You dont need to keep these definitions in a separate file from your \n#        other object definitions.  This has been done just to make things \n#        easier to understand. \n# \n############################################################################### \n \n \n \n############################################################################### \n############################################################################### \n# \n# CONTACT TEMPLATES \n# \n############################################################################### \n############################################################################### \n \n# Generic contact definition template - This is NOT a real contact, just a template! \n \ndefine contact{ \n        name                            generic-contact      ; The name of this contact template \n        service_notification_period     24x7   ; service notifications can be sent anytime \n        host_notification_period        24x7     ; host notifications can be sent anytime \n        service_notification_options    w,u,c,r,f,s  ; send notifications for all service states, flapping events, and scheduled downtime events \n        host_notification_options       d,u,r,f,s       ; send notifications for all host states, flapping events, and scheduled downtime events \n        service_notification_commands   notify-service-by-email  ; send service notifications via email \n        host_notification_commands      notify-host-by-email ; send host notifications via email \n        register                        0              ; DONT REGISTER THIS DEFINITION - ITS NOT A REAL CONTACT, JUST A TEMPLATE! \n        } \n \n \n \n \n############################################################################### \n############################################################################### \n# \n# HOST TEMPLATES \n# \n############################################################################### \n############################################################################### \n \n# Generic host definition template - This is NOT a real host, just a template! \n \ndefine host{ \n        name                            generic-host    ; The name of this host template \n        notifications_enabled           1        ; Host notifications are enabled \n        event_handler_enabled           1         ; Host event handler is enabled \n        flap_detection_enabled          1         ; Flap detection is enabled \n        failure_prediction_enabled      1        ; Failure prediction is enabled \n        process_perf_data               1            ; Process performance data \n        retain_status_information       1        ; Retain status information across program restarts \n        retain_nonstatus_information    1         ; Retain non-status information across program restarts \n  notification_period            24x7  ; Send host notifications at any time \n  max_check_attempts              3                       ; Re-check the service up to 3 times in order to determine its final (hard) state \n     check_command         check-host-alive \n    check_period  24x7 \n        register                        0         ; DONT REGISTER THIS DEFINITION - ITS NOT A REAL HOST, JUST A TEMPLATE! \n        } \n \n \n \n \n############################################################################### \n############################################################################### \n# \n# SERVICE TEMPLATES \n# \n############################################################################### \n############################################################################### \n \n# Generic service definition template - This is NOT a real service, just a template! \n \ndefine service{ \n        name                            generic-service  ; The name of this service template \n        active_checks_enabled           1         ; Active service checks are enabled \n        passive_checks_enabled          1               ; Passive service checks are enabled/accepted \n        parallelize_check               1         ; Active service checks should be parallelized (disabling this can lead to major performance problems) \n        obsess_over_service             1           ; We should obsess over this service (if necessary) \n        check_freshness                 1         ; Default is to NOT check service freshness \n        notifications_enabled           1         ; Service notifications are enabled \n        event_handler_enabled           1         ; Service event handler is enabled \n        flap_detection_enabled          1           ; Flap detection is enabled \n        failure_prediction_enabled      1          ; Failure prediction is enabled \n        process_perf_data               1         ; Process performance data \n        retain_status_information       1           ; Retain status information across program restarts \n        retain_nonstatus_information    1             ; Retain non-status information across program restarts \n        is_volatile                     0           ; The service is not volatile \n        check_period                    24x7   ; The service can be checked at any time of the day \n        max_check_attempts              3     ; Re-check the service up to 3 times in order to determine its final (hard) state \n        normal_check_interval           10; Check the service every 10 minutes under normal conditions \n        retry_check_interval            2     ; Re-check the service every two minutes until a hard state can be determined \n    notification_options     w,u,c,r          ; Send notifications about warning, unknown, critical, and recovery events \n        notification_interval           60       ; Re-notify about service problems every hour \n        notification_period             24x7      ; Notifications can be sent out at any time \n         register                        0              ; DONT REGISTER THIS DEFINITION - ITS NOT A REAL SERVICE, JUST A TEMPLATE! \n  ;action_url /pnp4nagios/graph?host=$HOSTNAME$&srv=$SERVICEDESC$ \n        }'  >/etc/icinga/lconf/default-templates.cfg

	echo -e '\ndefine timeperiod { \n timeperiod_name never \n alias never \n}' >/etc/icinga/lconf/timeperiod/never.cfg
	echo -e '\ndefine timeperiod { \n sunday 00:00-24:00 \n friday   00:00-24:00 \n  tuesday 00:00-24:00 \n saturday 00:00-24:00 \n  wednesday 00:00-24:00 \n thursday 00:00-24:00 \n monday 00:00-24:00 \n  timeperiod_name 24x7 \n  alias  24x7 \n}' >/etc/icinga/lconf/timeperiod/24x7.cfg
	echo -e "\ndefine hostgroup { \n hostgroup_name  $DOMAIN \n  alias $DOMAIN \n}" >/etc/icinga/lconf/hostgroups/$DOMAIN.cfg
	echo -e "\ndefine contactgroup { \n contactgroup_name EMS_Admin \n members $(echo $ADMINEMAILID | cut -d'@' -f1) \n  alias  EMS_Admin \n}" >/etc/icinga/lconf/contactgroups/EMS_Admin.cfg
	

}
# Checking OS distro and release version of os so according to it it can install packages 
function OSSPECS()
{
	# LSB_RELEASE=`/usr/bin/lsb_release -a`
	DISTRO="Unknown" ; RELEASE="Unknown"
	[[ -f /etc/issue.net ]] && DISTRO_FILE=`cat /etc/issue.net ` 
	if [ "$1" = "DISTRO" ]	
	then
		echo $DISTRO_FILE | head -1  | awk '{print $1}'
	elif [ "$1" = "RELEASE" ]
	then
		echo $DISTRO_FILE | head -1  | awk '{print $3}'
	fi
}


# Below function will install repository setup	
function INSTALLREPO()
{
	until [ "$ANSFORYUM" = "Y" ] || [ "$ANSFORYUM" = "y" ] || [ "$ANSFORYUM" = "N" ] || [ "$ANSFORYUM" = "n" ]
	do  
		printf "\n\nDo you want to continue with external repository? [Y/N] : "
		read ANSFORYUM    				
	done
	if [ "$ANSFORYUM" = "Y" ] || [ "$ANSFORYUM" = "y" ]
	then
		until [ "$SELREPO" = "1" ] || [ "$SELREPO" = "2" ]
		do
				printf "\nPlease Answer in numeric '1' OR '2' \n1) EFFONE \n2) EPEL\nSELECT ONE OF ALL ABOVE REPOSITORIES : "
				read SELREPO
		done
	else 
		PKGLIST=`$INSTALLER deplist $ICINGA_RPMS 2>/dev/null | grep provider | awk '{print $2}' | cut -d'.' -f1 | sort | uniq 2>/dev/null`
		echo "????????????????????????????????????????????????????????????????????????????????????????????????????????"
		echo "??????   Install Below Packages manually and Run this script again so Installation can go ahead   ??????"
		echo "????????????????????????????????????????????????????????????????????????????????????????????????????????"			
		echo $PKGLIST | tr ' ' '\n' | grep -v bash
		echo "CONFIG_ICINGA" > $STATFILE
		exit 0	
	fi
}


function PRINTINGPARA()
{
	
	# printf "\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\n"
	printf "@__________________________________________________________________________________________________________\n"
}


function GETADMINEMAILID()
{
	cd $INSTALLPATH
	if [ "$ADMINEMAILID" = "shankar.patel@effone.com" ]
	then
		printf "\n\nDefault Notifications will be sent to EFFONE EMS Administrator! Is it okay? [Y/N] : "
		read EMAILANS
		until [ "$EMAILANS" = "Y" ] || [ "$EMAILANS" = "y" ] || [ "$EMAILANS" = "N" ] || [ "$EMAILANS" = "n" ]
		do
			 printf "\nPlease Answer in 'Y/y' OR 'N/n' : "
			 read EMAILANS
		done
		if [ "$EMAILANS" = "N" ] || [ "$EMAILANS" = "n" ] 
		then
			printf "Please Give EmailID : "
			read ADMINEMAILID
			until [ `echo $ADMINEMAILID | grep '@' | wc -l` -eq 1 ]
			do
					printf "\nPlease Give Proper EmailID : "
					read ADMINEMAILID
			done
		fi
		echo "Thank You... All default notification will be sent to \"$ADMINEMAILID\" EMAIL-ID......"
	fi
}
function CHECKMYSQLINSTALLED()
{
	if [ ! -f /etc/init.d/mysqld ] && [ "$DB_HOST" = "localhost" ]
	then 
		ALL_RPMS="$ALL_RPMS mysql-server"
	else
		CHK_MY_SQL=`mysql $CREDENTIALS -e"show databases" &> /dev/null ; echo $?`
		if [ $CHK_MY_SQL -ne 0 ] 
		then
			if [ `ps -ef | grep mysqld.pid  | wc -l` -gt 0 ]
			then
				printf "Please provide mysql Admin username: "
				read DB_USER
				printf "Please provide $DB_USER password: "
				read DB_PASS
				if [ "$DB_PASS" = "" ]
				then 
					CREDENTIALS="-h $DB_HOST -u $DB_USER " 
					CHECK_MYSQL_CREDENTIALS="--hostname $DB_HOST --username $DB_USER "
				else
					CREDENTIALS="-h $DB_HOST -u $DB_USER -p$DB_PASS"
					CHECK_MYSQL_CREDENTIALS="--hostname $DB_HOST --username $DB_USER --password $DB_PASS"
				fi
			else
				echo "Please check your mysql server running or not???"
				exit 2
			fi	
		fi
	fi
}

# Below function defination for basic system setup and to be installed nagios packages from repository server
function SYSTEMCLEANUP()
{
	cd $INSTALLPATH
	rpm -qa | grep -e icinga -e openldap-server > /tmp/icinga_installed
	if [ `wc -l /tmp/icinga_installed | awk '{print $1}'` -ne 0 ]
	then  
		TRASH="/trash_old_config"
		echo -e "\nSystem Cleanup is going to start now ..........."
		PRINTINGPARA
		printf "\nIt will remove all installed below \n$(cat /tmp/icinga_installed) \n packages and move all configuration files, databases and folders of icinga package to $TRASH directory,\n\t\t Do you want to continue? [Y/N] : "
		read CLEANUPANS
		if [ "$CLEANUPANS" = "Y" ] || [ "$CLEANUPANS" = "y" ]
		then
			if [ -d $TRASH ] ; then mv $TRASH $TRASH`date +%s` >> $LOG_FILE && mkdir $TRASH && mv $TRASH`date +%s` $TRASH  
			else 
				mkdir $TRASH 
			fi
			printf "\n\nRemoving preinstalled packages.....\n\n\n">> $LOG_FILE
			PRINTINGPARA >> $LOG_FILE
			if [ "$LCONF_INSTALLED" = "y" ] 
			then 
				ICINGA_RPMS="$ICINGA_RPMS openldap-server*"
				mv /usr/local/LConf* $TRASH
				mv /etc/openldap $TRASH
				mv /var/lib/ldap/$TRASH
			fi 
			yum remove -y $ICINGA_RPMS openldap-server* &>> $LOG_FILE 
			rpm -e --noscripts icinga-idoutils-libdbi-mysql &>> $LOG_FILE
			printf "\n\nMoving preinstalled package config files.....\n\n\n">> $LOG_FILE
			mv /etc/icinga $TRASH/etc_icinga &>> $LOG_FILE  && echo "Moving icinga etc-icinga config to trash" >> $LOG_FILE
			mv /usr/share/icinga $TRASH/usr_share_icinga &>> $LOG_FILE  &&  echo "Moving usr-share-icinga to trash " >> $LOG_FILE
			mv /var/spool/icinga $TRASH/var_spool_icinga &>> $LOG_FILE  &&  echo "Moving var-spool-icinga to trash " >> $LOG_FILE
			mv /var/log/icinga $TRASH/var_log_icinga &>> $LOG_FILE  &&  echo "Moving var-log-icinga to trash " >> $LOG_FILE
			printf "\n\nTaking mysql dump and moving preinstalled dbs to trash folder.....\n\n\n" >> $LOG_FILE 
			mysqldump $CREDENTIALS icinga > /tmp/icinga.sql &>> $LOG_FILE && mv /tmp/icinga.sql $TRASH &>> $LOG_FILE && mysql $CREDENTIALS -e "drop database icinga; drop user icinga@$DB_HOST" &>> $LOG_FILE
		fi
		
	fi
	#Setting flag for next function
	echo "SYSTEM_INI_SETUP" > $STATFILE
	SYSTEM_INI_SETUP
}


function SYSTEM_INI_SETUP()
{
	# IPTABLES Rules to work with running firewall
    printf "\nInstalling Firewall rules for required port allowing to your private network only........\n"
	PRINTINGPARA >> $LOG_FILE
	printf "\n\nInstalling Firewall rules for required port allowing to your private network only.....\n\n\n" >> $LOG_FILE
	iptables -I INPUT -p tcp --dport 80 -j ACCEPT
	#iptables -I INPUT -p tcp --dport 80 -s $MYNETWORK_RANGE -j ACCEPT
    #iptables -I INPUT -p tcp --dport 5666 -s $MYNETWORK_RANGE -j ACCEPT
    #iptables -I INPUT -p tcp --dport 3306 -s $MYNETWORK_RANGE -j ACCEPT
	#iptables -I INPUT -p tcp --dport 389 -s $MYNETWORK_RANGE -j ACCEPT
	#iptables -I INPUT -s $MYNETWORK_RANGE -j ACCEPT
	#/etc/init.d/iptables save 2>&1 >> $LOG_FILE

	# Disabling SELINUX 
	printf "\nInstalling SELinux Setings........\n"
	PRINTINGPARA >> $LOG_FILE
	printf "\n\nInstalling SELinux Setings.....\n\n\n" >> $LOG_FILE
	setenforce 0 	
	echo -e "SELINUX=disabled \nSELINUXTYPE=targeted" > /etc/selinux/config
	yum clean all >> $LOG_FILE
	
	cd $INSTALLPATH
	if [ -d $INSTALLPATH/rpms ] 
	then
		if [ ! -f /etc/init.d/httpd ] ; then 
			cd $INSTALLPATH/rpms && rpm -i mailcap* httpd-tools-* apr-1* apr-util-* apr-util-ldap-* httpd-* httpd-tools-* &>>$LOG_FILE
			/etc/init.d/httpd restart &>>$LOG_FILE 
			if [ $? -ne 0 ] ; then echo "Cannot Restart httpd service !! " ; exit 2 ; fi
		else
			cd $INSTALLPATH
		fi
		if [ -d /var/www/html/rpms_effone ] 
		then
			ls /var/www/html/rpms_effone > $INSTALLPATH/old_repo_list
			ls $INSTALLPATH/rpms > $INSTALLPATH/new_repo_list
			DIFF=$(diff $INSTALLPATH/old_repo_list $INSTALLPATH/new_repo_list)
			if [ "$DIFF" != "" ] ; then mv /var/www/html/rpms_effone /var/www/html/old_rpm_effone ; fi	
			rm $INSTALLPATH/old_repo_list $INSTALLPATH/new_repo_list
		fi
		rpm -i $INSTALLPATH/rpms/createrepo-* $INSTALLPATH/rpms/python-deltarpm-* $INSTALLPATH/rpms/deltarpm-*  &>>$LOG_FILE 
		mv $INSTALLPATH/rpms /var/www/html/rpms_effone &>>$LOG_FILE
		cd $INSTALLPATH
		createrepo /var/www/html/rpms_effone &>>$LOG_FILE	
		chown apache:apache /var/www/html/rpms_effone -R
		/etc/init.d/httpd restart &>>$LOG_FILE 
	else
		echo "Package is not containing rpms folder......"
		exit 2;
	fi
	mv /etc/yum.repos.d $INSTALLPATH/ && cp /etc/yum.conf $INSTALLPATH/
	mkdir /etc/yum.repos.d
	echo > /etc/yum.conf
	echo -e "[EFFONE_YUM_REPO] \nname=local-copied-yum\nbaseurl=http://localhost/rpms_effone \ngpgcheck=0" > /etc/yum.repos.d/effone.repo
	AVAIL_PACKAGES=$($INSTALLER list | grep -e "icinga" -e "icinga-debuginfo" -e "icinga-devel" -e "icinga-doc" -e "icinga-gu" -e "icinga-gui-config" -e "icinga-idoutils" -e "icinga-idoutils-libdbi-mysql" | wc -l)
	PRINTINGPARA >> $LOG_FILE
	printf "\n\nSystem initial setup started now checking for required packages available or not.....\n\n\n" >> $LOG_FILE 
	if [ $AVAIL_PACKAGES -lt 7 ] 
	then
		printf "\nYour current repository configuration donot have required all icinga installation packages.\n\tYou must have in your repository all packages listed below :\n$(echo $ICINGA_RPMS | tr ' ' '\n\t')"
		INSTALLREPO
		if [ $SELREPO -eq 1 ]
		then
			printf "\n\nInstalling effone yum repository.....\n\n\n" >> $LOG_FILE
		#	echo -e "\n[EFFONE_OS_YUM_SERVER]\nname=$OSDISTRO-EFFONE\nbaseurl=http://$YUM_REPO_SERVER/yumrepo/$OSDISTRO/$OSRELEASE/$ARCH/\ngpgcheck=0\n" > /etc/yum.repos.d/effone.repo;
		#	echo -e "\n[EFFONE_ICINGA_YUM_SERVER]\nname=$OSDISTRO-EFFONE-ICINGA\nbaseurl=http://$YUM_REPO_SERVER/yumrepo/nagios/\ngpgcheck=0\n" >> /etc/yum.repos.d/effone.repo;
		#	echo -e "\n[EFFONE_PKG_YUM_SERVER]\nname=$OSDISTRO-EFFONE-PKG\nbaseurl=http://$YUM_REPO_SERVER/yumrepo/centos6.3/\ngpgcheck=0\n" >> /etc/yum.repos.d/effone.repo;			
		elif [ $SELREPO -eq 2 ]
		then
			echo -e "[icinga-stable-release]\nname=ICINGA (stable release for epel 6) \nbaseurl=http://packages.icinga.org/epel/6/release/\nenabled=1\ngpgcheck=1\ngpgkey=http://packages.icinga.org/icinga.key" > /etc/yum.repos.d/icinga-epel.repo;
		fi
	fi
	#Creating svn server host entry for uploading configuration to "svnems.effonetech.com"
	#echo "$svnhost  svnems.effonetech.com" >> /etc/hosts
	
	
	#Setting flag for next function
	echo "$ALL_VARIABLES" > $STATFILE
    echo "INSTALL_ICINGA" >> $STATFILE
	INSTALL_ICINGA
}

# ICINGA installation and configuration 
function INSTALL_ICINGA()
{
	cd $INSTALLPATH
	printf "\n\nStarting Installation of Icinga.............\n"
	PRINTINGPARA
	printf "\nStarting Installation of Icinga.....\n" >> $LOG_FILE
	PRINTINGPARA >> $LOG_FILE
	CHECKMYSQLINSTALLED
	$INSTALLER -y install $ALL_RPMS &>> $LOG_FILE
	if [ $? -ne 0 ]
    then
		echo -e "\nIcinga Installation Failed !!! Please check logs at $LOG_FILE"
		PRINTINGPARA 	
       	exit 2
	else
		echo -e "\nICINGA INSTALLATION DONE SUCCESSFULLY......"
		PRINTINGPARA  
       	fi
	sed 's/output_buffer_items=5000/output_buffer_items=0/g' /etc/icinga/idomod.cfg -i
	/etc/init.d/ido2db restart 2>&1 >> $LOG_FILE
	/etc/init.d/mysqld restart 2>&1 >> $LOG_FILE
	if [ $? -ne 0 ]; then echo "\nMysql Database Service startup issue ....!!!!, Please check logs in $LOG_FILE ." ;  exit 2 ; fi
	#Setting flag for next function
	echo "$ALL_VARIABLES" > $STATFILE
    echo "ICINGA_CONFIG" >> $STATFILE
	ICINGA_CONFIG
}
function ICINGA_CONFIG()
{
	cd $INSTALLPATH
	PRINTINGPARA >> $LOG_FILE
	printf "\n\nStarting ICINGA CONFIGURATION.....\n\n" >> $LOG_FILE
	# Default config Removal Part
    grep -v -e commands.cfg  -e contacts.cfg -e timeperiods.cfg -e templates.cfg -e localhost.cfg /etc/icinga/icinga.cfg > $INSTALLPATH/icinga.cfg && cat $INSTALLPATH/icinga.cfg > /etc/icinga/icinga.cfg
	CHECKMYSQLINSTALLED
	# icinga.cfg Additional configuration setup
	echo "broker_module=/usr/$LIBDIR/icinga/idomod.so config_file=/etc/icinga/idomod.cfg " >> /etc/icinga/icinga.cfg
	echo -e 'host_perfdata_command=process-host-perfdata\nservice_perfdata_command=process-service-perfdata\nhost_perfdata_file=/var/lib/icinga-perfdata/host-perfdata\nservice_perfdata_file=/var/lib/icinga-perfdata/service-perfdata\nservice_perfdata_file_template=DATATYPE::SERVICEPERFDATA\\tTIMET::$TIMET$\\tHOSTNAME::$HOSTNAME$\\tSERVICEDESC::$SERVICEDESC$\\tSERVICEPERFDATA::$SERVICEPERFDATA$\\tSERVICECHECKCOMMAND::$SERVICECHECKCOMMAND$\\tHOSTSTATE::$HOSTSTATE$\\tHOSTSTATETYPE::$HOSTSTATETYPE$\\tSERVICESTATE::$SERVICESTATE$\\tSERVICESTATETYPE::$SERVICESTATETYPE$\nhost_perfdata_file_template=DATATYPE::HOSTPERFDATA\\tTIMET::$TIMET$\\tHOSTNAME::$HOSTNAME$\\tHOSTPERFDATA::$HOSTPERFDATA$\\tHOSTCHECKCOMMAND::$HOSTCHECKCOMMAND$\\tHOSTSTATE::$HOSTSTATE$\\tHOSTSTATETYPE::$HOSTSTATETYPE$\nhost_perfdata_file_mode=a\nservice_perfdata_file_mode=a\nhost_perfdata_file_processing_interval=1\nservice_perfdata_file_processing_interval=1\nhost_perfdata_file_processing_command=process-host-perfdata-file\nservice_perfdata_file_processing_command=process-service-perfdata-file\ncfg_dir=/etc/icinga/lconf/contacts\ncfg_dir=/etc/icinga/lconf/contactgroups\ncfg_dir=/etc/icinga/lconf/commands\ncfg_dir=/etc/icinga/lconf/servicegroups\ncfg_dir=/etc/icinga/lconf/timeperiod\ncfg_file=/etc/icinga/lconf/default-templates.cfg\n' >> /etc/icinga/icinga.cfg
	echo -e "cfg_dir=/etc/icinga/lconf/icinga_$Domain\ncfg_file=/etc/icinga/lconf/hostgroups/$DOMAIN.cfg"  >> /etc/icinga/icinga.cfg	

	# Changes in config files
	sed 's/process_performance_data=0/process_performance_data=1/g' /etc/icinga/icinga.cfg -i	
  	sed 's/stalking_event_handlers_for_hosts=0/stalking_event_handlers_for_hosts=1/g' /etc/icinga/icinga.cfg -i	
  	sed 's/stalking_event_handlers_for_services=0/stalking_event_handlers_for_services=1/g' /etc/icinga/icinga.cfg -i	
  	sed 's/stalking_notifications_for_hosts=0/stalking_notifications_for_hosts=1/g' /etc/icinga/icinga.cfg -i	
  	sed 's/stalking_notifications_for_services=0/stalking_notifications_for_services=1/g' /etc/icinga/icinga.cfg -i	
	GETADMINEMAILID
  	sed "s/admin_email=icinga@localhost/admin_email=$ADMINEMAILID/g" /etc/icinga/icinga.cfg -i
	sed "s/icingaadmin/*/g" /etc/icinga/cgi.cfg -i
	sed 's/> $IcingaChkFile\ 2>\&1//g' /etc/init.d/icinga -i
	
	#Checking for perfdata directory if it is there or not.
	[[ ! -d /var/lib/icinga-perfdata ]] && mkdir /var/lib/icinga-perfdata
	chmod 776 /var/lib/icinga-perfdata/ && 	chown icinga:icinga /var/lib/icinga-perfdata/
	#Creating icinga Config files
	CREATEICINGACONFIGS
	cp /usr/bin/icingastats /usr/bin/nagiostats
	chown icinga:icinga /etc/icinga -R
	htpasswd -cmb /etc/icinga/passwd emsadmin emsadmin && chown apache:apache /etc/icinga/passwd 2>&1 >> $LOG_FILE 
	/etc/init.d/icinga checkconfig 2>&1 >> $LOG_FILE 
	if [ $? -ne 0 ]; then echo "\nICINGA Service startup issue ....!!!!, Please check logs in $LOG_FILE ." ; exit 2 ; fi
	/etc/init.d/httpd restart >> $LOG_FILE 2>&1
	if [ $? -ne 0 ]; then echo "\nApache Service startup issue ....!!!!, Please check logs in $LOG_FILE ." ;  exit 2 ; fi
	if [ ! -d $PLUGINDIR ] ; then mkdir -p $PLUGINDIR && cp -rf plugins/* $PLUGINDIR 
	else
		rsync -avz plugins/* $PLUGINDIR
	fi
	chown icinga:apache -R /var/lib/icinga-perfdata $PLUGINDIR
	chmod -R +x $PLUGINDIR
	echo -e "\nICINGA CONFIGURATION DONE SUCCESSFULLY......"
	PRINTINGPARA  
	#Setting flag for next function
	echo "$ALL_VARIABLES" > $STATFILE
	echo "INSTALL_ICINGA_WEB" >> $STATFILE
	INSTALL_ICINGA_WEB
}

function INSTALL_ICINGA_WEB()
{
	CHECKMYSQLINSTALLED
	cd $INSTALLPATH
	printf "\n\nDo you want to install ICINGA-WEB GUI in this host? [Y/N] : "
    read ICINGAWEB
    until [ "$ICINGAWEB" = "Y" ] || [ "$ICINGAWEB" = "y" ] || [ "$ICINGAWEB" = "N" ] || [ "$ICINGAWEB" = "n" ]
    do
		printf "\nPlease Answer in 'Y/y' OR 'N/n' : "
		read ICINGAWEB
	done
	if [ "$ICINGAWEB" = "Y" ] || [ "$ICINGAWEB" = "y" ] 
        then
		if [ -f /etc/httpd/conf.d/icinga-web.conf ] 
		then 			
			if [ `/etc/init.d/httpd status 2>&1 > /dev/null ; echo $?` -eq 0 ] ; then mv /etc/httpd/conf.d/icinga-web.conf $TRASH ; fi 
			if [ -d "/usr/local/icinga-web/" ] ; then mv /usr/local/icinga-web/ $TRASH ; fi
 			mysqldump $CREDENTIALS icinga_web > /tmp/icinga_web.sql && mv /tmp/icinga_web.sql $TRASH 
			mysql $CREDENTIALS -e "drop database icinga_web; drop user icinga_web@$DB_HOST ;"
		fi
		printf "\n\nInstallation and configuration of ICINGA-WEB GUI is statrted now.....\n"
		PRINTINGPARA  
		cd $INSTALLPATH/
		if [ -f $INSTALLPATH/icinga-web.tar.gz ]  ; then rm -f $INSTALLPATH/icinga-web.tar.gz ; fi
		if [ -d $INSTALLPATH/icinga-web ]  ; then rm -rf $INSTALLPATH/icinga-web ; fi
		wget -q http://localhost/rpms_effone/icinga-web.tar.gz
		tar -xvf icinga-web.tar.gz 2>&1 >> $LOG_FILE
		if [ $? -ne 0 ]; then printf "\nMight be downloaded tarball is currupted ....!!!!, Please check logs in $LOG_FILE." ; exit 2 ; fi
		cd icinga-web
		./configure  --prefix=/usr/local/icinga-web --with-web-user=apache --with-web-group=apache --with-web-path=/icinga-web --with-web-apache-path=/etc/httpd/conf.d/ --with-db-type=mysql --with-db-host=$DB_HOST --with-db-port=3306 --with-db-name=icinga_web --with-db-user=icinga_web --with-db-pass=icinga_web --with-conf-dir=etc/conf.d --with-log-folder=log --with-reporting-tmp-dir=app/modules/Reporting/data/tmp &>> $LOG_FILE
		if [ $? -ne 0 ]; then printf "\nIcinga-web Compilation issue ....!!!!, Please check logs in $LOG_FILE." ; exit 2 ; fi
		echo -e "\n\nCompilation started\n\n" >> $LOG_FILE
		make &>> $LOG_FILE  && make install &>> $LOG_FILE && make install-done &>> $LOG_FILE  && make install-apache-config  &>> $LOG_FILE && make install-javascript  &>> $LOG_FILE 
		if [ $? -ne 0 ]; then printf "\nInstallation issue ....!!!!, Please check logs in $LOG_FILE ." ; exit 2 ; fi
		# mysql -u root -e"CREATE DATABASE icinga_web; GRANT USAGE ON icinga_web.* TO 'icinga_web'@'localhost' IDENTIFIED BY 'icinga_web' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0; GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, INDEX ON icinga_web.* TO 'icinga_web'@localhost; "
		mysql $CREDENTIALS -e"CREATE DATABASE icinga_web ; grant all on icinga_web.* to icinga_web@$DB_HOST identified by 'icinga_web'"
		if [ $? -ne 0 ]; then echo "\nCannot Create icinga_web database.......!!!!!!" ; exit 2 ; fi
		cd ../
		mysql $CREDENTIALS icinga_web < $INSTALLPATH/icinga-web/etc/schema/mysql.sql
		if [ $? -ne 0 ]; then echo "\nCannot load icinga_web database.......!!!!!!" ; exit 2 ; fi
		chmod 775 /var/spool/icinga/cmd
		sed "s/instance\ name=\"default\">localhost/instance\ name=\"$DOMAIN_LOCATION\">$DOMAIN_LOCATION/g"  /usr/local/icinga-web/app/modules/Api/config/access.xml -i
		sed 's/usr\/local\/icinga\/etc\/objects/etc\/icinga\/lconf/g' /usr/local/icinga-web/app/modules/Api/config/access.xml -i
		sed 's/usr\/local\/icinga\/var\/rw/var\/spool\/icinga\/cmd/g' /usr/local/icinga-web/app/modules/Api/config/access.xml -i
		sed 's/usr\/local\/icinga\/bin\/icinga/usr\/bin\/icinga/g' /usr/local/icinga-web/app/modules/Api/config/access.xml -i
		sed 's/defaultHost>localhost/defaultHost>default/g' /usr/local/icinga-web/app/modules/Api/config/access.xml -i
		sed "s/host\ name=\"localhost\"/host\ name=\"$DOMAIN_LOCATION\"/g" /usr/local/icinga-web/app/modules/Api/config/access.xml -i
		/usr/local/icinga-web/bin/clearcache.sh
		echo -e "\n\nICINGA-WEB Installation and  Configuration DONE SUCCESSFULLY......"
		PRINTINGPARA  
	else 
		if [ "$ICINGA_MASTER" = "localhost" ]
	        then
				printf "\nProvide ICINGA-WEB GUI host address : "
				read ICINGA_MASTER
				until [ `echo $ICINGA_MASTER |cut -d '.' -f4` = "" ] 
				do
					printf "\nPlease Provide Proper host address : "
					read ICINGA_MASTER
					echo "Thank You... All Services can be viewd to $ICINGA_MASTER host......"
				done
	        fi		
	fi
	#Setting flag for next function
	echo "$ALL_VARIABLES" > $STATFILE
	echo "CONFIG_IDO" >> $STATFILE
	CONFIG_IDO	
}
# IDOUTILS Configuration to send data to mysql database
function CONFIG_IDO()
{
	CHECKMYSQLINSTALLED
	if [ "$ICINGAWEB" = "N" ] || [ "$ICINGAWEB" = "n" ] 
        then
		sed 's/socket_type=unix/socket_type=tcp/g' /etc/icinga/ido2db.cfg -i

		sed "s/instance_name=default/instance_name=$DOMAIN_LOCATION" /etc/icinga/idomod.cfg -i
		sed 's/output_type=unixsocket/output_type=tcpsocket/g' /etc/icinga/idomod.cfg -i
		sed "s/output=\/var\/spool\/icinga\/ido.sock/output=$ICINGA_MASTER/g"  /etc/icinga/idomod.cfg -i
		sed 's/output_buffer_items=0/output_buffer_items=5000/g' /etc/icinga/idomod.cfg -i
	
	else
		if [ `mysql -e'show databases' | grep 'icinga$'  | wc -l` -gt 0 ] 
		then
			mysql $CREDENTIALS -e "drop database icinga; drop user icinga@$DB_HOST" 
		fi
		mysql $CREDENTIALS -e"create database icinga  ; grant all on icinga.* to icinga@$DB_HOST identified by 'icinga' ;"
		if [ $? -ne 0 ]; then echo "\nCannot Create icinga database.......!!!!!!" ; exit 2 ; fi
		mysql $CREDENTIALS icinga  < `ls /usr/share/doc/icinga-idoutils-libdbi-* -d`/db/mysql/mysql.sql
		if [ $? -ne 0 ]; then echo "\nCannot load icinga database.......!!!!!!" ; exit 2 ; fi
		sed "s/db_host=localhost/db_host=$DB_HOST/g" /etc/icinga/ido2db.cfg -i
		#sed "s/db_port=3306/db_port=$MYSQL_PORT/g"  /etc/icinga/ido2db.cfg -i
		#sed "s/db_user=icinga/db_user=icinga/g" /etc/icinga/ido2db.cfg -i
		#sed "s/db_pass=icinga/db_pass=icinga/g" /etc/icinga/ido2db.cfg -i
		sed 's/debug_level=0/debug_level=2/g' /etc/icinga/ido2db.cfg -i
		sed 's/socket_type=unix/socket_type=tcp/g' /etc/icinga/ido2db.cfg -i
			
		sed "s/instance_name=default/instance_name=$DOMAIN_LOCATION/g" /etc/icinga/idomod.cfg -i
		sed 's/output_type=unixsocket/output_type=tcpsocket/g' /etc/icinga/idomod.cfg -i
		sed 's/output=\/var\/spool\/icinga\/ido.sock/output=127.0.0.1/g'  /etc/icinga/idomod.cfg -i
		sed 's/output_buffer_items=0/output_buffer_items=5000/g' /etc/icinga/idomod.cfg -i
	fi
	#Setting flag for next function
	echo "$ALL_VARIABLES" > $STATFILE
	echo "NRPE_CFG" >> $STATFILE
	NRPE_CFG
}
function NRPE_CFG()
{
	CHECKMYSQLINSTALLED
	echo -e 'command[check_openfiles]=/usr/bin/perl /usr/local/nagios/libexec/plugins/check_openfiles -w 1500 -c 2000\ncommand[check_current_users]=/usr/local/nagios/libexec/plugins/check_users -w 5 -c 10\ncommand[check_total_processes]=/usr/local/nagios/libexec/plugins/check_procs -w 550 -c 700\ncommand[check_procs_command]=/usr/local/nagios/libexec/plugins/check_procs -C $ARG1$ -c 1:\ncommand[check_procs_arg]=/usr/local/nagios/libexec/plugins/check_procs -a $ARG1$ -c 1:\ncommand[check_procs_arg_command]=/usr/local/nagios/libexec/plugins/check_procs -C $ARG1$ -a $ARG1$ -c 1:\ncommand[check_memory]=/usr/local/nagios/libexec/plugins/check_memory -w $ARG1$ -c $ARG2$\ncommand[check_swap]=/usr/local/nagios/libexec/plugins/check_swap -w $ARG1$ -c $ARG2$\ncommand[check_load_cpu]=/usr/local/nagios/libexec/plugins/check_load -w $ARG1$ -c $ARG2$\ncommand[check_disk]=/usr/local/nagios/libexec/plugins/check_disk -w $ARG1$ -c $ARG2$ -p $ARG3$\ncommand[check_icinga_service_checks_status]=/usr/local/nagios/libexec/plugins/check_file_age -f /var/spool/icinga/status.dat -w 10 -c 20 -W 100 -C 1000 command[check_file_status]=/usr/local/nagios/libexec/plugins/check_file_age -f $ARG1$ -w $ARG2$ -c $ARG3$' >> /etc/nagios/nrpe.cfg
	sed 's/dont_blame_nrpe=0/dont_blame_nrpe=1/g' /etc/nagios/nrpe.cfg -i
	#Setting flag for next function
	echo "$ALL_VARIABLES" > $STATFILE
	echo "VIEWDETAILS" >> $STATFILE
	VIEWDETAILS
}
function VIEWDETAILS()
{	
	# IDOUTILS and ICINGA service restart 
	/etc/init.d/ido2db stop &>> $LOG_FILE
	/etc/init.d/icinga stop &>> $LOG_FILE
	mysql $CREDENTIALS -e"drop database icinga ; create database icinga "  &>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "\nCannot drop old db and create new icinga database.......!!!!!!" ; exit 2 ; fi
	mysql $CREDENTIALS icinga  < `ls /usr/share/doc/icinga-idoutils-libdbi-* -d`/db/mysql/mysql.sql  &>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "\nCannot load icinga database.......!!!!!!" ; exit 2 ; fi
	chkconfig icinga on
	/etc/init.d/icinga start	&>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "\nICINGA Service start-up issue ....!!!!, Please check logs in $LOG_FILE ." ; exit 2 ;  fi
	chkconfig ido2db on 
	/etc/init.d/ido2db start &>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "\nIDO2DB Service start-up issue ....!!!!, Please check logs in $LOG_FILE ." ; exit 2 ; fi
	
	#NRPE Service Restart
	/etc/init.d/nrpe restart  &>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "\nNRPE Service start-up issue ....!!!!, Please check logs in $LOG_FILE ." ; exit 2 ; fi
	chkconfig nrpe on	
	#Apache Service Restart
	/etc/init.d/httpd restart &>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "\nApache Service start-up issue ....!!!!, Please check logs in $LOG_FILE ." ;  exit 2 ; fi
	chkconfig httpd on
	now=`date +%s`
	commandfile='/var/spool/icinga/cmd/icinga.cmd'
	echo -e "$SERVICELIST" > svclist && cat svclist | while read SERVICE COMMAND
	do
		printf "[$now] SCHEDULE_FORCED_SVC_CHECK;ICINGA_$DOMAIN;$SERVICE;$now\n" > $commandfile
	done
	#Setting flag for next function
	echo "INGRAPH_INSTALL" > $STATFILE
	INGRAPH_INSTALL
}
	

# Install ingraph
function INGRAPH_INSTALL
{
	CHECKMYSQLINSTALLED
	printf "\n\nInstallation and configuration of INGRAPH Addon is started now.....\n"
	PRINTINGPARA  
	printf "\n\nInstallation and configuration of INGRAPH Addon is started now.....\n">> $LOG_FILE
	PRINTINGPARA  >> $LOG_FILE
	CHECKMYSQLINSTALLED
	if [ -f /etc/init.d/ingraph ] 
	then 			
			if [ -d "/etc/ingraph" ] ; then mv /etc/ingraph $TRASH && echo -e "\n\nCopied /etc/ingraph folder to $TRASH directory.....\n" ; fi
			rm -f  /etc/init.d/ingraph*
 			mysqldump $CREDENTIALS ingraph > /tmp/ingraph.sql && mv /tmp/ingraph.sql $TRASH 
			mysql $CREDENTIALS -e "drop database ingraph; drop user ingraph@$DB_HOST ;"			
	fi
	useradd ingraph &>> $LOG_FILE
	wget -q http://localhost/rpms_effone/SQLAlchemy-0.8.2.tar.gz &>> $LOG_FILE
	tar -xvf SQLAlchemy-0.8.2.tar.gz &>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "SQLAlchemy-0.8.2.tar.gz Package is currupted couldnot extract it.....!!!!" ; exit 2 ; fi
	cd SQLAlchemy-0.8.2 
	python setup.py install &>> $LOG_FILE
	cd ../
	if [ $? -ne 0 ]; then echo "SQLAlchemy-0.8.2.tar.gz Package couldnot installed.....!!!!" ; exit 2 ; fi
	wget -q http://localhost/rpms_effone/inGraph.1.0.2.tar.gz
	tar -xvf inGraph.1.0.2.tar.gz &>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "inGraph.1.0.2.tar.gz Package is currupted couldnot extract it.....!!!!" ; exit 2 ; fi
	cd inGraph.1.0.2
	python setup.py install &>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "inGraph.1.0.2.tar.gz Package couldnot installed.....!!!!" ; exit 2 ; fi
	sed 's/www-data/apache/g' ./icinga-web/setup-icinga-web.sh -i
	./icinga-web/setup-icinga-web.sh --install --prefix=/usr/local/icinga-web &>> $LOG_FILE
	mysql $CREDENTIALS -e"CREATE DATABASE ingraph ; grant all on ingraph.* to ingraph@$DB_HOST identified by 'ingraph'"
	echo -e 'INGRAPH_COLLECTOR_CHDIR="/etc/ingraph" \nINGRAPH_COLLECTOR_PIDFILE="/var/run/ingraph/ingraph-collectord.pid" \nINGRAPH_COLLECTOR_PERFDATA_DIR="/var/lib/icinga-perfdata" \nINGRAPH_COLLECTOR_PERFDATA_PATTERN="*-perfdata.*[0-9]" \nINGRAPH_COLLECTOR_FILE_LIMIT="5" \nINGRAPH_COLLECTOR_FILE_MODE="REMOVE" \nINGRAPH_COLLECTOR_SLEEPSECS="1" \nINGRAPH_COLLECTOR_USER="icinga" \nINGRAPH_COLLECTOR_GROUP="icinga" \nINGRAPH_COLLECTOR_LOGFILE="/var/log/icinga/ingraph-collector.log" ' > /etc/default/ingraph-collector
	echo -e 'INGRAPH_CHDIR=/etc/ingraph \nINGRAPH_PIDFILE=/var/run/ingraph/ingraphd.pid \nINGRAPH_USER=icinga'> /etc/default/ingraph
	if [ $? -ne 0 ]; then echo "\nCannot Create ingraph database.......!!!!!!" ; exit 2 ; fi
	cd ../
	/etc/init.d/ingraph restart &>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "\nCannot Start ingraph Service.......!!!!!!" ; exit 2 ; fi
	/etc/init.d/ingraph-collector restart &>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "\nCannot Start ingraph-collector Service.......!!!!!!" ; exit 2 ; fi
	/usr/local/icinga-web/bin/clearcache.sh &>> $LOG_FILE
	
	#Setting flag for next function
	echo "$ALL_VARIABLES" > $STATFILE
	echo "BUSINESS_PROCESS" >> $STATFILE
	BUSINESS_PROCESS
}
function BUSINESS_PROCESS()
{	 
	printf "\n\nInstallation and configuration of Business Process Addon is started now.....\n"
	PRINTINGPARA  
	printf "\n\nInstallation and configuration of Business Process Addon is started now.....\n">> $LOG_FILE
	PRINTINGPARA  >> $LOG_FILE
	CHECKMYSQLINSTALLED
	if [ -d /usr/local/nagiosbp ] 
	then 			
			mv /usr/local/nagiosbp $TRASH 
			echo -e "\n\nCopied /usr/local/nagiosbp folder to $TRASH directory.....\n"
	fi
	cd $INSTALLPATH
	if [ `perl -e "use CGI::Simple"; echo $?` -ne 0 ] ; then echo "Installation is incomplete...! Please install perl-CGI-Simple..!!!!!" ; exit 2 ; fi
	if [ `perl -e "use DBI"; echo $?` -ne 0 ] ; then echo "Installation is incomplete...! Please install perl-DBI..!!!!!" ; exit 2 ; fi
	if [ `perl -e "use JSON::XS"; echo $?` -ne 0 ] ; then echo "Installation is incomplete...! Please install perl-JSON-XS..!!!!!" ; exit 2 ; fi
	if [ `perl -e "use LWP::UserAgent"; echo $?` -ne 0 ] ; then echo "Installation is incomplete...! Please install perl-LWP..!!!!!" ; exit 2 ; fi
	wget -q http://localhost/rpms_effone/nagios-business-process-addon-0.9.6.tar.gz &>> $LOG_FILE
	tar -xvf nagios-business-process-addon-0.9.6.tar.gz &>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "nagios-business-process-addon-0.9.6.tar.gz Package is currupted couldnot extract it.....!!!!" ; exit 2 ; fi
	cd nagios-business-process-addon-0.9.6
	./configure --with-nagcgiurl=/cgi-bin/icinga --with-naghtmurl=/icinga --with-nagetc=/etc/icinga --with-apache-authname="Icinga Access" --mandir=/usr/local/share/man &>> $LOG_FILE
	if [ $? -ne 0 ]; then printf "\nCompilation issue ....!!!!, Please check logs in $LOG_FILE." ; exit 2 ; fi
	make install &>> $LOG_FILE
	if [ $? -ne 0 ]; then printf "\nBusiness Process Addon couldn't installed ....!!!!, Please check logs in $LOG_FILE." ; exit 2 ; fi
	mv /usr/local/nagiosbp/etc/nagios-bp.conf* /usr/local/nagiosbp/etc/nagios-bp.conf
	printf "icinga = ICINGA_EFFONE;net_smtp & ICINGA_EFFONE;nrpe_icinga_service_checks_status & ICINGA_EFFONE;nrpe_procs_icinga & ICINGA_EFFONE;nrpe_procs_nrpe & ICINGA_EFFONE;nrpe_procs_syslog \ndisplay 0;icinga;icinga \n \nmysql = ICINGA_EFFONE;net_mysql_connection_time & ICINGA_EFFONE;net_mysql_icinga & ICINGA_EFFONE;net_mysql_icinga_web & ICINGA_EFFONE;net_mysql_ingraph & ICINGA_EFFONE;net_mysql_slow_queries & ICINGA_EFFONE;net_mysql_uptime & ICINGA_EFFONE;nrpe_procs_mysql \ndisplay 0;mysql;mysql \n \nido2db = ICINGA_EFFONE;nrpe_ido2db_service_checks_status & ICINGA_EFFONE;nrpe_procs_ido2db & mysql \ndisplay 0;ido2db;ido2db \n \nicinga-core = icinga & ido2db \ndisplay 0;icinga-core;icinga-core \n \nhttp = ICINGA_EFFONE;nrpe_procs_httpd \ndisplay 0;http;http \n \nicinga-web = http & mysql \ndisplay 0;icinga-web;icinga-web \n \ningraph = ICINGA_EFFONE;nrpe_disk_/ & ICINGA_EFFONE;nrpe_procs_ingraph & ICINGA_EFFONE;nrpe_procs_ingraph-collector & mysql \ndisplay 0;ingraph;ingraph \n \nMonitoring-App = icinga-core & icinga-web & ingraph \ndisplay 1;Monitoring-App;Monitoring-App" > /usr/local/nagiosbp/etc/nagios-bp.conf
	mv /usr/local/nagiosbp/etc/ndo.cfg* /usr/local/nagiosbp/etc/ndo.cfg
	sed 's/ndodb_database=nagios/ndodb_database=icinga/g' -i /usr/local/nagiosbp/etc/ndo.cfg
	sed "s/ndodb_host=localhost/ndodb_host=$DB_HOST/g" -i /usr/local/nagiosbp/etc/ndo.cfg
	sed "s/ndodb_username=nagiosro/ndodb_username=icinga/g" -i /usr/local/nagiosbp/etc/ndo.cfg
	sed 's/ndodb_password=dummy/ndodb_password=icinga/g' -i /usr/local/nagiosbp/etc/ndo.cfg
	sed 's/ndodb_prefix=nagios_/ndodb_prefix=icinga_/g' -i /usr/local/nagiosbp/etc/ndo.cfg
	sed 's/ndofs_instance_name=default/ndofs_instance_name=DOMAIN_LOCATION/g' -i /usr/local/nagiosbp/etc/ndo.cfg
	grep -v -e AuthUserFile -e Require -e AuthName -e AuthType /etc/httpd/conf.d/nagiosbp.conf > /tmp/nbp-http.conf
	cat /tmp/nbp-http.conf > /etc/httpd/conf.d/nagiosbp.conf 
	sudo -u apache /usr/local/nagiosbp/bin/nagios-bp-consistency-check.pl &>> $LOG_FILE
	until [ $? -eq 0 ]
	do
		chmod +x /usr/local/nagiosbp/bin/nagios-bp-consistency-check.pl
		sudo -u apache /usr/local/nagiosbp/bin/nagios-bp-consistency-check.pl &>> $LOG_FILE
	done
	/usr/local/nagiosbp/libexec/check_bp_status.pl -b icinga &>> $LOG_FILE
		if [ $? -eq 0 ] ; then echo -e "\n????????????????????????????????????????????????????????????????????????????????????? \nBusiness Process Addon is not working properly....\n????????????????????????????????????????????????????????????????????????????????????? \n" ; fi
	cd ../
	wget -q http://localhost/rpms_effone/icinga-cronk-bp.tar &>> $LOG_FILE
	tar -xvf icinga-cronk-bp.tar &>> $LOG_FILE
	if [ $? -ne 0 ]; then echo "nagios-business-process-addon-0.9.6.tar.gz Package is currupted couldnot extract it.....!!!!" ; exit 2 ; fi
	cd icinga-cronk
	./install.sh &>> $LOG_FILE
	if [ $? -ne 0 ]; then printf "\nBusiness Process Icinga-cronk installation issue ....!!!!, Please check logs in $LOG_FILE." ; exit 2 ; fi
	cd ..
	chown -R apache:apache /usr/local/nagiosbp/etc/
	
	#Setting flag for next function
	echo "$ALL_VARIABLES" > $STATFILE
	echo "REVERTBACK" >> $STATFILE
	REVERTBACK
}
function REVERTBACK()
{
	mv /var/www/html/rpms_effone $INSTALLPATH/rpms  &>>$LOG_FILE
	rm -f /etc/yum.repos.d/effone.repo && mv $INSTALLPATH/yum.repos.d/*.repo  /etc/yum.repos.d/ &>> $LOG_FILE
	rm -f /etc/yum.conf && mv $INSTALLPATH/yum.conf /etc
	chown icinga:apache  /var/spool/icinga/cmd -R
	sleep 5
	CHOWN=`ls -l /var/spool/icinga/cmd/icinga.cmd | awk '{print $3"."$4}'` &>> $LOG_FILE
	until [ "$CHOWN" = "icinga.apache" ] 
	do 
		chown icinga:apache  /var/spool/icinga/cmd -R
		sleep 2
		CHOWN=`ls -l /var/spool/icinga/cmd/icinga.cmd | awk '{print $3"."$4}'` &>> $LOG_FILE
	done
	#Setting flag for next function
	echo "$ALL_VARIABLES" > $STATFILE
	#echo "BACKUP_SETUP" >> $STATFILE
	#BACKUP_SETUP
}

function BACKUP_SETUP()
{
	CHECKMYSQLINSTALLED
	if [ -d /root/emk_backup ] ; then rm -rf /root/emk_backup ; fi
	mkdir /root/emk_backup
	cp $INSTALLPATH/rpms/backup.sh  /root/emk_backup
	sed "s/CREDENTIALS/$CREDENTIALS/g" /root/emk_backup/backup.sh -i
	echo 'rsync -avz /etc/icinga /root/emk_backup/ 
rsync -avz /usr/local/icinga-web/app /root/emk_backup/ 
rsync -avz /etc/httpd/conf.d /root/emk_backup/
rsync -avz /usr/local/nagiosbp /root/emk_backup/
find /root/emk_backup/ -iname "*.swp" -type f -exec rm -f {} \;' >> /root/emk_backup/backup.sh
	
	# Setting crone for everyday backup
	echo '1 1 * * * root /bin/sh /root/emk_backup/backup.sh' > /etc/cron.d/emkbackup 
	
	#Setting flag for next function
	echo "$ALL_VARIABLES" > $STATFILE
	echo "CREATE_CONFIGREPO" >> $STATFILE
	CREATE_CONFIGREPO
}


function CREATE_CONFIGREPO()
{
	[[ -d /opt/configrepo ]]  && rm -rf  /opt/configrepo_old   &>> $LOG_FILE && mv /opt/configrepo /opt/configrepo_old  &>> $LOG_FILE
    if [ "$SNV_USER" = "" ] && [ "$SVN_PASS" != "" ]
	then
		SVN_CREDENTIALS=""
	else
		SVN_CREDENTIALS="--username $SVN_USER --password $SVN_PASS"
	fi
	SVNTEST=`svn ls $SVN_CREDENTIALS $SVN_URL&>/dev/null; echo $?`
	if [ "$SVN_URL" = "" ] 
	then
		printf "\n\nDo you want to install backup repository on this host or have external repository? \n"
		echo "1) LOCAL ( On this host )"
		echo "2) EXTERNAL"
		printf "\nSelect 1 OR 2 : "
		read ANSFORREPOCREATE 
		until [ "$ANSFORREPOCREATE" = "1" ] || [ "$ANSFORREPOCREATE" = "2" ] 
		do  
			printf "\nPlease Answer in numeric '1' OR '2' \n1) LOCAL ( On this host ) \n2) EXTERNAL\nSELECT ONE OF ALL ABOVE TWO : "
			read ANSFORREPOCREATE			
		done
		if [ "$ANSFORREPOCREATE" = "2" ]
		then
			printf "\nProvide External SVN URL: "
			read SVN_URL
			printf "\nProvide External SVN USER: "
			read SVN_USER
			printf "\nProvide External PASSWORD for $SVN_USER: "
			read SVN_PASS
		else 
			svnadmin create /opt/configrepo 
			chown apache:apache -R /opt/configrepo
			printf "<Directory "/opt/configrepo">\n        AllowOverride All\n        Options MultiViews -Indexes Includes FollowSymlinks\n        <IfModule mod_access.c>\n                Order allow,deny\n                Allow from all\n        </IfModule>\n</Directory>\n<Location /configrepo>\n        DAV svn\n        SVNPath /opt/configrepo\n        AuthType Basic\n        AuthName “EMK”\n        AuthUserFile /etc/icinga/passwd\n        Require valid-user\n</Location>\n" > /etc/httpd/conf.d/effone_emk.conf
			/etc/init.d/httpd restart >> $LOG_FILE 2>&1
			SVN_CREDENTIALS="--username emsadmin --password emsadmin"
			SVN_URL="http://localhost/configrepo"
		fi
	fi
	svn co -q $SVN_URL /root/emk_backup $SVN_CREDENTIALS
	cp -rf /etc/icinga /root/emk_backup
	cp -rf /usr/local/icinga-web/app/ /root/emk_backup/
	cp -rf /etc/httpd/conf.d /root/emk_backup/ 
	cp -rf /usr/local/nagiosbp /root/emk_backup/ 
	svn add -q /root/emk_backup/* 
	svn ci -q /root/emk_backup/* $SVN_CREDENTIALS -m"Creating Structure for Configuration" 
	echo 'svn add  $(svn st /root/emk_backup/icinga | sed -n "s/^[A?] *\(.*\)/\1/p")'  >>/root/emk_backup/backup.sh 
	echo 'svn add  $(svn st /root/emk_backup/app | sed -n "s/^[A?] *\(.*\)/\1/p")'  >>/root/emk_backup/backup.sh 
	echo 'svn add  $(svn st /root/emk_backup/conf.d | sed -n "s/^[A?] *\(.*\)/\1/p")'  >>/root/emk_backup/backup.sh 
	echo 'svn add  $(svn st /root/emk_backup/nagiosbp | sed -n "s/^[A?] *\(.*\)/\1/p")' >>/root/emk_backup/backup.sh 
	echo "svn ci -q /root/emk_backup -m'\`date +%s\`' $SVN_CREDENTIALS " >>/root/emk_backup/backup.sh
	
	#Setting flag for next function
	echo "$ALL_VARIABLES" > $STATFILE
	echo "REPOSYNC_WITH_EFFONE" >> $STATFILE
	REPOSYNC_WITH_EFFONE
}
function REPOSYNC_WITH_EFFONE()
{
	printf "\n\nDo you want to SYNC backup with EFFONE repository? [ Y/N ] : "
	read ANSFORREPOSYNC 
	until [ "$ANSFORREPOSYNC" = "Y" ] || [ "$ANSFORREPOSYNC" = "y" ] || [ "$ANSFORREPOSYNC" = "N" ] || [ "$ANSFORREPOSYNC" = "n" ]
	do  
		printf "\n\nPlease give answer only in Y/y OR N/n : "
		read ANSFORREPOSYNC			
	done
	EXT_SVN_URL_NEW=1
	if [ "$ANSFORREPOSYNC" = "Y" ] || [ "$ANSFORREPOSYNC" = "y" ]
	then
		until [ "$EXT_SVN_URL_NEW" = "0" ] 
		do  
			printf "\n\nGiven SVN URL is not correct \nDo you want to continue with other repository? [Y/N] : "
			read EXT_SVN_URL_NEW
			if [ "$EXT_SVN_URL_NEW" = "Y" ] || [ "$EXT_SVN_URL_NEW" = "y" ]
			then	
				printf "\nProvide External SVN URL: "
				read EXT_SVN_URL
				printf "\nProvide External SVN USER: "
				read EXT_SVN_USER
				printf "\nProvide External PASSWORD for $SVN_USER: "
				read EXT_SVN_PASS
				EXT_SVN_URL_NEW=`rm -rf $INSTALLPATH/test 2>&1 > /dev/null ; mkdir $INSTALLPATH/test 2>&1 > /dev/null ; svn co -q $EXT_SVN_URL --username $EXT_SVN_USER --passowrd $EXT_SVN_PASS $INSTALLPATH/test 2>&1 > /dev/null; echo $? `
				# ADD Next statements to create synchronization with  effone repo
			else
				EXT_SVN_URL_NEW=0
			fi	
			
		done	
	fi
	
	echo -e "\n##########################################################################\n#\tEMK INSTALLATION DONE SUCCESSFULLY\n##########################################################################"
	rm $STATFILE 		
}


#intialize of variables
ldap_conf_path='/etc/openldap/slapd.d/cn=config'
SERVERSTATUS="FRESH"
SLAP="EmsAdmin"
LOG_FILE="/tmp/emk_install.log"
OSDISTRO=`OSSPECS DISTRO`
OSRELEASE=`OSSPECS RELEASE`
YUM_REPO_SERVER="yumrepo.effone.com"
DB_HOST="localhost"
DB_USER="root"
DB_PASS=""
INSTALLPATH="$(cd `dirname $0` && pwd)"
INSTALLER="yum"
BUSINESS_PROC_MOD="perl-CGI-Simple* perl-DBI* perl-JSON-XS* perl-LWP* "
ICINGA_RPMS="icinga icinga-debuginfo icinga-devel icinga-doc icinga-gui icinga-gui-config icinga-idoutils icinga-idoutils-libdbi-mysql "
ALL_RPMS="$INGRAPH_MOD $BUSINESS_PROC_MOD $ICINGA_RPMS mod_dav_svn gcc glibc MySQL-python openldap-clients subversion nrpe openldap-servers perl-LDAP php php-cli php-curl php-gd php-ldap php-mysql php-pdo php-pear php-soap php-xmlrpc php-xsl python-devel python-setuptools python-sqlalchemy rsync wget net-snmp net-snmp-libs net-snmp-devel net-snmp-perl net-snmp-python net-snmp-utils libedit make"
STATFILE="/tmp/LAST_EXIT_STATUS"
SELREPO=0
ANSFORYUM=""
SVN_CREDENTIALS=""
ICINGA_MASTER="localhost"
PLUGINDIR="/usr/local/nagios/libexec/plugins"
ADMINEMAILID="shankar.patel@effone.com"
SVN_CREDENTIALS=""
SVN_URL=""
SVN_USER=""
SVN_PASS=""
>$LOG_FILE
SERVICELIST='net_mysql_connection_time check_mysql!connection-time
net_mysql_icinga  check_mysql_perm!icinga!icinga!icinga
net_mysql_icinga_web  check_mysql_perm!icinga_web!icinga_web!icinga_web
net_mysql_ingraph  check_mysql_perm!ingraph!ingraph!ingraph
net_mysql_slow_queries check_mysql!"slow-queries"
net_mysql_uptime check_mysql!uptime
net_ping check-host-alive
net_smtp check_smtp
net_ssh check_ssh
nrpe_disk_/ check_nrpe1!check_disk!20 10 /
nrpe_icinga_service_checks_status check_nrpe1!check_file_status!/var/spool/icinga/status.dat 10 20
nrpe_ido2db_service_checks_status  check_nrpe1!check_file_status!/var/log/icinga/ido2db.debug 10 20
nrpe_load check_nrpe1!check_load_cpu!5,6,7 9,10,11
nrpe_loggedin_users check_nrpe!check_current_users
nrpe_memory check_nrpe1!check_memory!80% 90%
nrpe_openfiles check_nrpe!check_openfiles
nrpe_procs_httpd  check_nrpe1!check_procs_command!httpd
nrpe_procs_icinga  check_nrpe1!check_procs_command!icinga
nrpe_procs_ido2db  check_nrpe1!check_procs_command!ido2db
nrpe_procs_ingraph  check_nrpe1!check_procs_arg_command!python ingraphd
nrpe_procs_ingraph-collector  check_nrpe1!check_procs_arg_command!python ingraph_collectord
nrpe_procs_mysql check_nrpe1!check_procs_command!mysqld
nrpe_procs_nrpe check_nrpe1!check_procs_command!nrpe
nrpe_procs_syslog check_nrpe1!check_procs_command!rsyslogd
nrpe_swap check_nrpe1!check_swap!"70% 50%"
nrpe_total_procs check_nrpe!check_total_processes'
if [ `uname -r | grep x86_64 | wc -l` -eq 1 ] ; then 
	ARCH=x86_64 
	LIBDIR="lib64"
else 
	ARCH=i386
	LIBDIR="lib"
fi


# Get Command line arguments for installing icinga with some proper details
while getopts "d:n:e:l:m:p:u:U:P:Sh" OPT; do
        case $OPT in
            "d") domain_name=$OPTARG;;
			"n") MYNETWORK_RANGE=$OPTARG;;
			"l") LOCATION=$OPTARG;;
			"e") ADMINEMAILID=$OPTARG;;
			"m") DB_HOST=$OPTARG;;
			"u") DB_USER=$OPTARG;;
			"p") DB_PASS=$OPTARG;;
			"s") SVN_URL=$OPTARG;;
			"U") SVN_USER=$OPTARG;;
			"P") SVN_PASS=$OPTARG;;
          	"h") USAGE;;
		*)USAGE;;
        esac
done

#Checks if FDN is provided or not if not provided script will not run.
if [ "$domain_name" = "" ] || [ "$MYNETWORK_RANGE" = "" ] || [ "$LOCATION" = "" ] 
then
	echo "Please provide all the credentials ......!!!!!!!"
	USAGE;
	exit 2
fi

# Deviding FQDN in domain and tld 2 parts so later on we can put in ldap configuration
DOMAIN=$(echo $domain_name | awk -F"." '{print $1}'|tr '[:lower:]' '[:upper:]')
Domain=$(echo $domain_name | awk -F"." '{print $1}')
TLD=$(echo $domain_name | awk -F"." '{print $2}')
LOCATION=$(echo $LOCATION |tr '[:lower:]' '[:upper:]')
DOMAIN_LOCATION="$DOMAIN-$LOCATION"
if [ "$DB_PASS" = "" ]
then 
	CREDENTIALS="-h $DB_HOST -u $DB_USER " 
	CHECK_MYSQL_CREDENTIALS="--hostname $DB_HOST --username $DB_USER "
else
	CREDENTIALS="-h $DB_HOST -u $DB_USER -p$DB_PASS"
	CHECK_MYSQL_CREDENTIALS="--hostname $DB_HOST --username $DB_USER --password $DB_PASS"
fi
CHECKMYSQLINSTALLED

echo -e "\n##########################################################################\n\tEMK MASTER SERVER SCRIPT STARTED INSTALLATION\n##########################################################################\n"
PRINTINGPARA
PRINTLOGO
PRINTINGPARA


#checking status of the script if 1st time installation it will be executed from starting or based on the flag status it will execute the next function
if [ "$OSDISTRO" != "CentOS" ] && [ "$OSRELEASE" != "6.3" ]
then
	echo -e "\nSorry your OperatingSystem is not supported with current EMS Package.It has tobe as below : \n\tOperatingSystem : CentOS\n\tRelease Version\t: 6.3"
	exit 2;
elif [ -f $STATFILE ] 
then
	LAST_EXIT_STATUS=$(cat $STATFILE | tail -1)
	cd $INSTALLPATH
	$LAST_EXIT_STATUS
	exit;
else
	if [ ! -f /usr/bin/yum ] 
	then 
		echo -e "\n\n\t Yum command is not installed. \nInstallation cannot continue ...! Please install 'yum' command to complete installation."
		exit 2
	fi
	cd $INSTALLPATH
	SYSTEMCLEANUP
fi
if [ "$ICINGAWEB" != "N" ] || [ "$ICINGAWEB" != "n" ] 
then
		echo -e "\n##########################################################################\n#\tEMK SERVER INSTALLATION DONE SUCCESSFULLY\n##########################################################################"
		PRINTINGPARA
		echo -e "#\tICINGA-WEB URL: http://`hostname`/icinga-web\n#\tDefault username/password to login into the ICINGA-WEB are  'root/password'"
		PRINTINGPARA
		echo -e "##########################################################################\n##########################################################################\n"
fi
