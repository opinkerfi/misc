#!/bin/sh

INSTALL_DIR=`dirname $0`
NAGIOS_SERVER=$1


if [ -z $NAGIOS_SERVER ] ; then
	echo "Usage: $0 <IP_ADDRESS_OF_NAGIOS>"
	exit 1
fi


echo 'rpm -ihv http://opensource.is/repo/ok-release-6-5.noarch.rpm'
rpm -Uhv http://opensource.is/repo/ok-release-6-5.noarch.rpm > /dev/null

echo 'yum install -y nrpe nagios-okplugin-check_yum nagios-plugins-load nagios-plugins-procs  nagios-plugins-swap'
yum install -y nrpe nagios-okplugin-check_yum nagios-plugins-load nagios-plugins-procs  nagios-plugins-swap  nagios-plugins-check_cpu > /dev/null


echo "cp -r $INSTALL_DIR/$HOSTTYPE/etc/nrpe.d/ /etc/"
'cp' -r $INSTALL_DIR/$HOSTTYPE/etc/nrpe.d/ /etc/

echo "cp -r $INSTALL_DIR/$HOSTTYPE/usr/ /"
'cp' -ar $INSTALL_DIR/$HOSTTYPE/usr/ /

echo "Modifying /etc/nagios/nrpe.cfg"

test -f /etc/nagios/nrpe.cfg && cp /etc/nagios/nrpe.cfg /etc/nagios/nrpe.cfg-old
cat $INSTALL_DIR/$HOSTTYPE/etc/nagios/nrpe.cfg | sed "s/IP_ADDRESS_OF_NAGIOS/$NAGIOS_SERVER/" > /etc/nagios/nrpe.cfg

service nrpe start
chkconfig nrpe on
