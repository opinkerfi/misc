#!/bin/bash
#
# Copyright 2013, Tomas Edwardsson
#
# This script is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Enumerates interfaces and their operstate (up/down/unknown).

for dev in /sys/class/net/*
do
	if [ ! -d "${dev}" ]; then
		continue
	fi
	devname=$(basename ${dev})
	echo -n ${devname}:
	cat ${dev}/operstate;
done
exit 0
