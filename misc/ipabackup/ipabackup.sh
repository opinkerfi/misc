#!/bin/bash
#
# ipabackup - backup script for freeipa

# Copyright (C) 2012 Tomas Edwardsson <tommi@tommi.org>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


# Keep backups
BACKUP_DAYS=10

# Manager password (with I wouldn't have to save this here
MANAGER_PW=''

# Directory Manager DN
ROOTDN='cn=directory manager'

# Directory Server Name, eg EXAMPLE-COM
DIRSRV_NAME=''

# PKI Infrastructure Name, usually PKI-IPA
PKIDIRSRV_NAME='PKI-IPA'


DIRSRV_SCRIPTDIR="/var/lib/dirsrv/scripts-${DIRSRV_NAME}"
PKIDIRSRV_SCRIPTDIR="/usr/lib64/dirsrv/slapd-${PKIDIRSRV_NAME}"

(
echo "Started at $(date)"
${DIRSRV_SCRIPTDIR}/db2bak.pl -D "${ROOTDN}" -w "${MANAGER_PW}"
${PKIDIRSRV_SCRIPTDIR}/db2bak.pl -D "${ROOTDN}" -w "${MANAGER_PW}"


find /var/lib/dirsrv/slapd-${PKIDIRSRV_NAME}/bak -maxdepth 1 -mindepth 1 -mtime +${BACKUP_DAYS} -exec rm -rf {} \;
find /var/lib/dirsrv/slapd-${DIRSRV_NAME}/bak -maxdepth 1 -mindepth 1 -mtime +${BACKUP_DAYS} -exec rm -rf {} \;

echo
echo "Done at $(date)"

) &>> /var/log/ipabackup.log

