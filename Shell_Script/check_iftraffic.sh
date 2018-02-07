#!/bin/bash
#####
#The plugin will find the IP address on the server and checks it belongs to which network (dmz, int, mit or sto) and on which interface. After that, it  captures the traffic of that interface at every 5 mins and provide it in MB/s..
#Created by Shankar Patel- Brodos India
#Create date : 21-11-2012
#Updated date : 28-02-2013
################################################################################

function help {
        echo "The plugin will check the range of ip network.
        Usage:
                $0 <ip_network_range>
                Please provide ip range as a argument.
        examples:
                $0 172.19
                OK. sto: eth0 [up] | traffic_mit=1mb "
       exit 3;
}

if [[ "$1" = "" ]]; then  help ; fi

DATA_DIR=`/usr/bin/dirname $0`
ipaddrs="$1"
interface=`ip addr | grep -v 'lo:' | grep " $ipaddrs" | grep 'scope global' |sed 's/ \+/ /g' | awk '{print $5$7$8}' | sed 's/secondary//g' | sed 's/scope//g' | cut -d':' -f1 | uniq | grep -v '^$'| tail -1`
DATA_FILE="$DATA_DIR/.iftraffic"_$interface"_"$1
if [[ "`echo $interface | wc -c`" -le 1 ]] ; then echo "Unknown: not assigned any ip of this ip range to this host." ; exit 3 ; fi
input_data() {
        NEW_DATA=$CUR_CHK_TIME":"$TOT_IN_MB":"$TOT_OUT_MB
        echo $NEW_DATA > $DATA_FILE
        chown nagios:nagios $DATA_FILE 2>/dev/null
        chown nagios:nagios /tmp/.net_data_$ipaddrs 2>/dev/null
}
exit_out() {
                                                                input_data
        CUR_IN_MB=`echo "scale=3 ; $TOT_IN_MB-$LAST_IN_MB" | bc`
        CUR_OUT_MB=`echo "scale=3 ; $TOT_OUT_MB-$LAST_OUT_MB" | bc `
                                                                in_comp=`echo "$TOT_IN_MB<$LAST_IN_MB" | bc`
                                                                out_comp=`echo "$TOT_OUT_MB<$LAST_OUT_MB" | bc`
                                                                if [[ "$in_comp" -eq 1 ]] || [[ "$out_comp" -eq 1 ]];then CUR_IN_MB=0 ; CUR_OUT_MB=0 ; fi

        echo "OK. $msg: $interface [up], in="$CUR_IN_MB"MB, out="$CUR_OUT_MB"MB | traffic_"$msg"_in="$CUR_IN_MB"MB traffic_"$msg"_out=$CUR_OUT_MB"MB
}

ip1=$(echo $ipaddrs | awk -F'.' '{print $1}')
ip2=$(echo $ipaddrs | awk -F'.' '{print $2}')
if [[ "$ip1" -eq 172 ]]; then
        case $ip2 in
                17)
                        msg="mit";;
                18)
                        msg="int";;
                19)
                        msg="dmz";;
                24)
                        msg="brodosphone";;
                30)
                        msg="sto";;
        esac
else
        echo "CRITICAL. Interface seems down."
        exit 2;
fi

old_data_fetch() {
        if [[ "`grep ':$' $DATA_FILE 1> /dev/null ;echo $?`" = "0" ]] || [[ "`grep '::' $DATA_FILE 1> /dev/null ;echo $?`" = "0" ]]
        then
                                                                                                input_data
        fi
        LAST_CHK_TIME=`cat $DATA_FILE | sed 's/:/ /g' | awk '{print $1}'`
        LAST_IN_MB=`cat $DATA_FILE | sed 's/:/ /g' | awk '{print $2}'`
        LAST_OUT_MB=`cat $DATA_FILE | sed 's/:/ /g' | awk '{print $3}'`
}
new_data_fetch() {
        cat /proc/net/dev > /tmp/.net_data_$ipaddrs
        CUR_CHK_TIME=`date +%s`
        if [[ "$LAST_IN_MB" = "" ]]  ; then LAST_IN_MB=0  ; fi
        if [[ "$LAST_OUT_MB" = "" ]]  ; then LAST_OUT_MB=0  ; fi
        CUR_IN_BYTES=`cat /tmp/.net_data_$ipaddrs | sed s/^/\ /g | grep " $interface:"|  cut -d':' -f2 | awk '{print $1}'`
        TOT_IN_KB=`echo "$CUR_IN_BYTES/1024" | bc`
        TOT_IN_MB=`echo "scale=3 ; $TOT_IN_KB/1024" | bc`
        CUR_OUT_BYTES=`cat /tmp/.net_data_$ipaddrs | sed s/^/\ /g | grep " $interface:"|  cut -d':' -f2 | awk '{print $9}'`
        TOT_OUT_KB=`echo "$CUR_OUT_BYTES/1024" | bc `
        TOT_OUT_MB=`echo "scale=3 ; $TOT_OUT_KB/1024" | bc`
}
new_data_fetch
if [[ ! -f $DATA_FILE ]] ; then
                                                                input_data
        echo "OK. Saving Initial values to File."
        exit 0
fi
old_data_fetch
exit_out

