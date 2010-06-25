# Copyright 2010, Tomas Edwardsson 
#
# This puppet recipe is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This puppet recipe distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class dns {

    file { "resolvconf":
	name	=> "/etc/resolv.conf",
        owner   => root,
        group   => root,
        mode    => 644,
        source  => [
            "puppet://$server/dns/resolv.conf.$hostname",
            "puppet://$server/dns/resolv.conf.$os.$osver",
            "puppet://$server/dns/resolv.conf.$os",
            "puppet://$server/dns/resolv.conf",
	],
	sourceselect => first

    }
}

