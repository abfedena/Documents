#!/bin/sh
#############################################################################
#
#The script checks if there is any error in any received and transmit packats on 
#given interface.
#
#############################################################################
#
#Created on 20th Aug 2012
#Created by Shankar Patel - Brodos India Team
#Deployed date : 11th Dec 2012
#Last Modified : 11th Dec 2012
#Last Modified by : Shankar Patel - Brodos India Team
##############################################################################

crit=0
ok_i=0
crit_interface=""
ok_interface=""

## checking up interfaces
#ip addr | grep "state UP" | awk -F':' '{print $2}' | sed 's/\ //g' > /tmp/.up_inet
shankar=`ip addr | grep "UP" | grep -v 'lo:' | awk -F':' '{print $2}' | sed 's/\ //g'`
# It will check error for each interfaces which are up
for INTERFACE in $(echo $shankar)
do
 err_rec=`ifconfig $INTERFACE | grep 'RX packets' | tail -1 | awk '{print $3}' | cut -d':' -f2`
 err_trans=`ifconfig $INTERFACE | grep 'TX packets' |tail -1 | awk '{print $3}' | cut -d':' -f2`
 if [ "$err_rec" -gt 0 ] || [ "$err_trans" -gt 0 ]
 then
  crit_interface="$crit_interface $INTERFACE has Received Error=$err_rec and Transimt Error=$err_trans"
  crit=$(($crit+1))
 else
  ok_interface="$ok_interface $INTERFACE"
  ok_i=$(($ok_i+1))
 fi
done

if [ "$crit_interface" != "" ]
then
 echo "WARNING. $crit_interface. | error_interface=$crit error_recieved=$err_rec error_transmit=$err_trans"
 exit 1;
else
 echo "OK. $ok_interface up and no error found. | error_interface=$crit error_recieved=$err_rec error_transmit=$err_trans "
 exit 0;
fi
#echo > /tmp/.up_inet
