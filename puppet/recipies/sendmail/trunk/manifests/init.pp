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

class sendmail {
	package { "sendmail-cf": ensure => installed }

	exec { "sendmail-update":
		command => "make -C /etc/mail",
		refreshonly => true,
		subscribe => [ File["/etc/mail/sendmail.mc"], File["/etc/mail/submit.mc"] ],
	}

	service { "sendmail":
		ensure => running,
		hasstatus => true,
		enable => true,
		subscribe => [ File["/etc/mail/sendmail.mc"], File["/etc/mail/submit.mc"], Package["sendmail-cf"]],
	}

	file { "/etc/mail/sendmail.mc":
		owner   => root,
		group   => root,
		mode    => 644,
		source  => [
			"puppet://$server/sendmail/sendmail.mc.$hostname",
			"puppet://$server/sendmail/sendmail.mc.$os.$osver",
			"puppet://$server/sendmail/sendmail.mc.$os",
			"puppet://$server/sendmail/sendmail.mc",
		],
		sourceselect => first
	}
	file { "/etc/mail/submit.mc":
		owner   => root,
		group   => root,
		mode    => 644,
		source  => [
			"puppet://$server/sendmail/submit.mc.$hostname",
			"puppet://$server/sendmail/submit.mc.$os.$osver",
			"puppet://$server/sendmail/submit.mc.$os",
			"puppet://$server/sendmail/submit.mc",
		],
		sourceselect => first
	}
}


