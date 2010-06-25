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

class iptables {
    service { "iptables":
        subscribe => File[iptablesconfig],
        enable => true,
        ensure => running,
        hasstatus => true
    }

    file { "iptablesconfig":
        name    => "/etc/sysconfig/iptables",
        owner   => root,
        group   => root,
        mode    => 640,
        source  => [
            "puppet://$server/iptables/iptables.$hostname",
            "puppet://$server/iptables/iptables.$os",
            "puppet://$server/iptables/iptables",
        ],
        sourceselect => first
    }
}

