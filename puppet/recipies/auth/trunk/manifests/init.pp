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
	package { "nscd": ensure => installed }
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
	}
	class kerberos {
		augeas { "kerberos":
			context => "/files/etc/sysconfig/authconfig",
			changes => "set USEKERBEROS yes",
			onlyif => "get USEKERBEROS != yes",
			notify => Exec["authconfig-update"],
			subscribe => Package["pam_krb5"],
		}
		package { "pam_krb5": ensure => installed }
	}
	class ldap {
		augeas { "ldap":
			context => "/files/etc/sysconfig/authconfig",
			changes => "set USELDAP yes",
			onlyif => "get USELDAP != yes",
			notify => Exec["authconfig-update"],
			subscribe => Package["nss_ldap"],
		}
		augeas { "ldapauth":
			context => "/files/etc/sysconfig/authconfig",
			changes => "set USELDAPAUTH yes",
			onlyif => "get USELDAPAUTH != yes",
			notify => Exec["authconfig-update"],
			subscribe => Package["nss_ldap"],
		}
		package { "nss_ldap": ensure => installed }
	}


	file { "/etc/krb5.conf":
		owner   => root,
		group   => root,
		mode    => 644,
		source  => [
			"puppet://$server/auth/krb5.conf.$hostname",
			"puppet://$server/auth/krb5.conf.$os.$osver",
			"puppet://$server/auth/krb5.conf.$os",
			"puppet://$server/auth/krb5.conf",
		],
		sourceselect => first
	}
	file { "/etc/ldap.conf":
		mode => 0644,
		owner => root,
		group => root,
		source  => [
			"puppet://$server/auth/ldap.conf.$hostname",
			"puppet://$server/auth/ldap.conf.$os.$osver",
			"puppet://$server/auth/ldap.conf.$os",
			"puppet://$server/auth/ldap.conf",
		],
		sourceselect => first,
	}
	file { "/etc/openldap/ldap.conf":
		ensure => link,
		target => "/etc/ldap.conf",
	}

	exec { "Invalidate NSCD cache and restart daemon":
		subscribe => [ File["/etc/ldap.conf"], File["/etc/krb5.conf"] ],
		path => "/bin:/usr/bin:/usr/sbin:/sbin",
		command => "nscd -i passwd;nscd -i group;/sbin/service nscd restart",
		refreshonly => true
	}

	service { "nscd":
		subscribe => [ File["/etc/ldap.conf"], File["/etc/krb5.conf"], Package["nscd"] ],
		enable => true,
		ensure => running,
		hasstatus => true
	}
}


