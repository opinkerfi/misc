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

class auth {
	package { "augeas": ensure => installed }
	exec { "authconfig-update":
		command => "/usr/bin/authconfig --updateall",
		refreshonly => true,
	}
	class mkhomedir {
		augeas { "mkhomedir":
			context => "/files/etc/sysconfig/authconfig",
			changes => "set USEMKHOMEDIR yes",
			onlyif => "get USEMKHOMEDIR != yes",
			notify => Exec["authconfig-update"],
		}
		file { "/home/os":
			name => "/home/os",
			ensure => directory,
			mode => 0755
		}
		file { "/os":
			name => "/os",
			ensure => link,
			target => "/home/os"
		}
	}
	class kerberos {
		augeas { "kerberos":
			context => "/files/etc/sysconfig/authconfig",
			changes => "set USEKERBEROS yes",
			onlyif => "get USEKERBEROS != yes",
			notify => Exec["authconfig-update"],
		}
	}
	class ldap {
		augeas { "ldap":
			context => "/files/etc/sysconfig/authconfig",
			changes => "set USELDAP yes",
			onlyif => "get USELDAP != yes",
			notify => Exec["authconfig-update"],
		}
		augeas { "ldapauth":
			context => "/files/etc/sysconfig/authconfig",
			changes => "set USELDAPAUTH yes",
			onlyif => "get USELDAPAUTH != yes",
			notify => Exec["authconfig-update"],
		}
	}
}

