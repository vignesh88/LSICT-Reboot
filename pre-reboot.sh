#!/bin/bash
#author vignesh_ragupathy@yahoo.com
## Version 2.1

PATH=$PATH:/usr/sbin::/usr/bin:/sbin:/bin:

VER="2.1"
VERSION="Server restart check script $VER "



usage() {
  echo "WARNING, use this script AT YOUR OWN RISK"
  echo "    Usage: `basename $0` [OPTIONS]"
  echo "    -v          output version information and exit"
  echo "    -h          display this help and exit"
}

while getopts ":vh" Option
do
  case $Option in
    v     ) echo $VERSION;exit;;
    h     ) usage;exit;;
    *     ) echo "Unimplemented option chosen. Try -h for help!";exit 1;;   # DEFAULT
  esac
done


## test if user = root
#
if [ `id|cut -c5-11` != "0(root)" ] ; then
  echo -e "You must run this script as Root\n"
  exit 1
 fi

##################






mkdir -p /usr/local/stats/script_RB_check

###Check running services###
/sbin/service --status-all |grep running... |awk '{print $1}' > /usr/local/stats/script_RB_check/b_services

##check network services ##
/etc/init.d/network status |grep active -A 1 |sed -n 2,5p >> /usr/local/stats/script_RB_check/b_services

###check iptables ###
/etc/init.d/iptables status |grep "Firewall is not running" > /dev/null
if [ $? != 0 ]; then
echo iptables >> /usr/local/stats/script_RB_check/b_services
fi
###check total memory###
free -m |grep Mem |awk '{print $2}' > /usr/local/stats/script_RB_check/b_memory

##check mounted volumes###
df -Ph |awk '{print $NF}' |sed -n 2,100p > /usr/local/stats/script_RB_check/b_mounted

#check sysctl values##
/sbin/sysctl -a |grep -v kernel.random.uuid |grep -v random.entropy_avail |grep -v fs.inode |grep -v fs.dentry-state |perl -lape 's/\s+//sg'  > /usr/local/stats/script_RB_check/b_sysctlvalues

##check multipath##
which multipath 2> /dev/null
if [ $? == 0 ]; then
        multipath -ll |grep failed -B 3 |grep HP |awk '{print $2}' |sed s/"("//g |sed s/")"//g > /usr/local/stats/script_RB_check/b_failed_luns
        multipath -ll |grep HP |awk '{print $2}' |sed s/"("//g |sed s/")"//g > /usr/local/stats/script_RB_check/b_all_luns
        rm -f /usr/local/stats/script_RB_check/b_active_luns
                for lun in `cat /usr/local/stats/script_RB_check/b_all_luns`
                do
                grep $lun /usr/local/stats/script_RB_check/b_failed_luns > /dev/null
                        if [ $? == 0 ]; then
                        echo " " > /dev/null
                        else
                        echo $lun >> /usr/local/stats/script_RB_check/b_active_luns
                        fi
                done
else
echo " " > /dev/null
fi

