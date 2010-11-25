#!/bin/sh

INSTALL_DIR=`dirname $0`
NAGIOS_SERVER=$1


if [ -z $NAGIOS_SERVER ] ; then
	echo "Usage: $0 <IP_ADDRESS_OF_NAGIOS>"
	exit 1
fi


rpm -ihv http://opensource.is/repo/rhel5/x86_64/ok-release-5-3.noarch.rpm
yum install -y nrpe nagios-okplugin-check_yum
yum install -y nagios-plugins-load nagios-plugins-procs  nagios-plugins-swap


cp -r $INSTALL_DIR/$HOSTTYPE/etc/nrpe.d/ /etc/

test -f /etc/nagios/nrpe.cfg && cp /etc/nagios/nrpe.cfg /etc/nagios/nrpe.cfg-old
cat $INSTALL_DIR/$HOSTTYPE/etc/nagios/nrpe.cfg | sed "s/IP_ADDRESS_OF_NAGIOS/$NAGIOS_SERVER/" > /etc/nagios/nrpe.cfg

service nrpe start
chkconfig nrpe on
