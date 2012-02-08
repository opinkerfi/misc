#!/bin/bash
LINE=`/usr/lib/nagios/plugins/check_procs $*`
RC=$?
COUNT=`echo $LINE | awk '{print $3}'`
echo $LINE \| procs=$COUNT
exit $RC
