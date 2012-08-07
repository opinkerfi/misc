#!/bin/bash

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


# Based loosely on the work of Andrey Ivanov <andrey ivanov polytechnique fr>

function getdmpass() {
	echo -n "cn=directory manager password: " 1>&2
	stty -echo
	read DMPASS
	stty echo
	echo 1>&2
	echo "${DMPASS}"
}

# Generate tmpdir
MYTMPDIR=$(mktemp -d /tmp/ipaback.XXXXXXXXXX)

# Get the directory manager password
DMPASS=$(getdmpass)

if [ -z "${MYTMPDIR}" ]; then
	echo mktemp failed, aborting
	exit 1
fi

# Generate password
BACKUPPW=$(openssl rand -base64 18)
echo "Generated password \"${BACKUPPW}\" for cn=backupuser,cn=config, please save it now (Enter to continue)"
echo "For instance in ipabackup.sh"

# Create ldif for backupuser
cat <<EOLDIF > ${MYTMPDIR}/backupuser.ldif
dn: cn=backupuser, cn=config
objectClass: top
objectClass: person
cn: backupuser
sn: backupuser
userPassword: ${BACKUPPW}
description: Backup user for automated backups
EOLDIF

# Add ACI for the backuptask
cat <<EOLDIF > ${MYTMPDIR}/backuptask-aci.ldif
dn: cn=tasks,cn=config
changetype: modify
add: aci
aci: (target="ldap:///cn=backup,cn=tasks,cn=config")(version 3.0;acl "Backup user can launch backup jobs";allow (add)(userdn = "ldap:///cn=backupuser,cn=config");)
EOLDIF

# Add entries to the directory server
echo Adding user to Directory Server
ldapadd -D "cn=directory manager" -w "${DMPASS}" -f ${MYTMPDIR}/backupuser.ldif

echo Adding tasks ACI to Directory Server
ldapmodify -D "cn=directory manager" -w "${DMPASS}" -f ${MYTMPDIR}/backuptask-aci.ldif

# Add entries to the PKI directory server
echo Adding user to PKI-IPA Directory Server
ldapadd -h localhost -p 7389 -D "cn=directory manager" -w "${DMPASS}" -f ${MYTMPDIR}/backupuser.ldif

echo Adding tasks ACI to PKI-IPA Directory Server
ldapmodify -h localhost -p 7389 -D "cn=directory manager" -w "${DMPASS}" -f ${MYTMPDIR}/backuptask-aci.ldif


echo "Cleaning up"
rm -rf ${MYTMPDIR}

