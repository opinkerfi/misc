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

class ntp {

    package { ntp: ensure => latest }

    service { "ntpd":
	subscribe => File[ntpconf],
	enable => true,
	ensure => running,
        hasstatus => true
    }

    file { "ntpconf":
	name	=> "/etc/ntp.conf",
        owner   => root,
        group   => root,
        mode    => 640,
        source  => [ 
            "puppet://$server/ntp/ntp.conf.$hostname",
            "puppet://$server/ntp/ntp.conf",
	],
	sourceselect => first,
	subscribe => Package["ntp"],
    }

    file { "step-tickers":
	name	=> "/etc/ntp/step-tickers",
        owner   => root,
        group   => root,
        mode    => 640,
        source  => [ 
            "puppet://$server/ntp/step-tickers.$hostname",
            "puppet://$server/ntp/step-tickers",
	],
	sourceselect => first,
	subscribe => Package["ntp"],
    }
}


