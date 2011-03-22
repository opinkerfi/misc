#!/usr/bin/perl 
#
# Copyright 2011, Tomas Edwardsson 
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


use strict;
use warnings;
use MIME::Lite;
use MIME::Entity;
use MIME::Base64;

# Some defaults
my $pnp4nagios_perfdata = '/var/lib/pnp4nagios/perfdata';
my $pnp4nagios_phpdir = '/usr/share/nagios/html/pnp4nagios';
my $nagios_cgiurl = "http://nagios/nagios/cgi-bin";
my $pnp4nagios_url = "http://nagios/nagios/pnp4nagios/";
my $from_address = 'nagios@opensource.is';
my $logo = '/usr/share/nagios/html/images/sblogo.png';

my $alert_type = 'service';
my $recipient = '';
my $date = '';
my $type = '';
my $host = '';
my $hostalias = '';
my $ip = '';
my $state = '';
my $message = '';
my $servicedesc = '';


sub usage() {
	print STDERR <<"	EOUSAGE";
$0 [-H] <email> <date_string> <notification_type> <hostname> <host_alias> <host_address> <state> <notification_string> [servicedesc]

    -H			Host notification, skip servicedesc

    email			Recipient of notification
    date_string		eg, Fri Oct 13 00:30:28 CDT 2000
    notification_type	One of the following types:
		PROBLEM, RECOVERY, ACKNOWLEDGEMENT, FLAPPINGSTART, FLAPPINGSTOP,
		FLAPPINGDISABLED, DOWNTIMESTART, DOWNTIMEEND or
		DOWNTIMECANCELLED
    hostname		Hostname of affected device
    host_alias		Hostname alias, descriptive
    host_address		IP Address of device
    state			State of affected device
	host		UP, DOWN or UNREACHABLE
	service		OK, WARNING, UNKNOWN or CRITICAL
    notification_string	The description of what went wrong
    servicedesc		Service Description of device

	EOUSAGE

	exit 3;
}

my @cleansed_argv = ();
# Look for service or host options, default to service
foreach my $a (@ARGV) {
	if ($a eq '-H' or $a eq '--host') {
		$alert_type = 'host';
	} else {
		push @cleansed_argv, $a;
	}
}


if (($alert_type eq 'service' and @cleansed_argv != 9) or ($alert_type eq 'host'
	and @cleansed_argv != 8)) {
	usage();
}


# Assign variable from cmd line
if ($alert_type eq 'service') {
	($recipient, $date, $type, $host, $hostalias, $ip, $state, $message, $servicedesc) = @cleansed_argv;
} else {
	($recipient, $date, $type, $host, $hostalias, $ip, $state, $message) = @cleansed_argv;
}


# Nagios Command int, see nagios src, nagios/include/common.h
my %nagioscmd = (
	host_downtime => 55,
	host_ack => 33,
	service_downtime => 56,
	service_ack => 34,
);



# Locate graph for machine and attach to message
# Based on pnp4nagios v0.4.X not tested with v0.6.X

my $rrd = '';


# Get the specified service graph
if ($alert_type eq 'service' and -f "$pnp4nagios_perfdata/$host/$servicedesc.rrd") {
	my $t = time();
	$rrd = `( cd $pnp4nagios_phpdir;php -r 'parse_str("host=$host&srv=$servicedesc&source=1&view=0&end=$t&display=image", \$_GET); include_once("index.php");' )`;
# Get the specified HOST graph
} elsif ($alert_type eq 'host' and -f "$pnp4nagios_perfdata/$host/_HOST_.rrd") {
	my $t = time();
	$rrd = `( cd $pnp4nagios_phpdir;php -r 'parse_str("host=$host&srv=_HOST_&source=1&view=0&end=$t&display=image", \$_GET); include_once("index.php");' )`;
}


# Now we build the message
# MESSAGE Structure
#	HEAD PART multipart/related
#		ALT PART multipart/alternative
#			text content part text/plain
#			html_content part text/html
#		RRD IMAGE PART image/png
#		LOGO IMAGE PART image/png <sblogo.png>

# The real envelope (TOP PART)
my $head = MIME::Entity->build(
	Type		=> 'multipart/related',
	From		=> $from_address,
	To		=> $recipient,
	Subject		=> "Nagios, $state - $host" . ($servicedesc ? " - $servicedesc" : ""),
);

# Alternative part for text and html content
my $alt = MIME::Entity->build(
	Type		=> 'multipart/alternative'
);
my $txt_content = MIME::Entity->build(
	Type		=> 'text/plain',
	Charset		=> 'UTF-8',
	Encoding	=> 'quoted-printable',
	Data		=> sprintf(<<EO, ($servicedesc ? "\nService: $servicedesc" : "")),
Host: $host ($ip)%s
State: $state
Date: $date
Notification Type: $type
Description: $message
EO
);

my $state_color = '#33FF00';

if ($state eq 'WARNING' or $state eq 'UNREACHABLE') {
	$state_color = '#FFFF00';
} elsif ($state eq 'CRITICAL' or $state eq 'DOWN') {
	$state_color = '#F83838';
}


my $ack = '';
if ($state ne 'OK' and $state ne 'UP') {
	my $ackurl = sprintf("%s/cmd.cgi?host=%s%s",
		$nagios_cgiurl,
		$host,
		($servicedesc ? "&service=$servicedesc" : ""));
	$ack = qq{
  <tr>
    <td colspan="1" style="background: black;color: white;font-weight: bold">Service Actions</td>
    <td colspan="1" style="background: white;color: black"><a class="cmd" href="$ackurl&cmd_typ=} . 
	# Service or host ack
	($alert_type eq 'service' ? $nagioscmd{service_ack} : $nagioscmd{host_ack}) . 
	qq{">Acknowledge</a> <a class="cmd" href="$ackurl&cmd_typ=} . 
	# Service or host downtime
	($alert_type eq 'service' ? $nagioscmd{service_downtime} : $nagioscmd{host_downtime}) . 
	qq{">Schedule Downtime</a></td>
  </tr>
};
}

my $html_content = MIME::Entity->build(
	Type		=> 'text/html',
	Charset		=> 'UTF-8',
	Encoding	=> 'quoted-printable',
	Data		=> qq{
<head>
<style type="text/css">
th {
	background: black;
	color: white;
	font-weight: bold;
	text-align: left;
	width: 220px;
}
a {
	text-decoration: underline;
	font-weight: bold;
	font-size: 90%;
	color: black;
}
a.cmd {
	padding: 2px;
	margin: 5px 5px 5px 0px;
	border: solid 1px black;
	background: #eee;
	float: right;
}
</style>
</head>
<body>
<table style="background: #ddd;width: 604px">
  <tr>
    <th colspan="2"><img src="cid:sblogo.png"></td>
  </tr>
  <tr>
    <th>Host</td>
    <td style="background: white;color: black"><a style="color: black;text-decoration: underline" href="$nagios_cgiurl/extinfo.cgi?type=1&host=$host">$host ($ip)</a></td>
  </tr>} .
	($alert_type eq 'host' ? "" : qq{
  <tr>
    <th>Service</td>
    <td style="background: white;color: black"><a style="color: black;text-decoration: underline" href="$nagios_cgiurl/extinfo.cgi?type=2&host=$host&service=$servicedesc">$servicedesc</a></td>
  </tr>}) . qq{
  <tr>
    <th>State</td>
    <td style="background: $state_color;color: black;font-weight: bold">$state</td>
  </tr>
  <tr>
    <th>Date</td>
    <td style="background: white;color: black">$date</td>
  </tr>
  <tr>
    <th>Type</td>
    <td style="background: white;color: black">$type</td>
  </tr>
$ack
  <tr>
    <th colspan="2">Description</td>
  </tr>
  <tr>
    <td colspan="2" style="background: white;color: black">$message</td>
  </tr>
} . ($rrd ? qq{
  <tr>
    <td style="background: white" colspan="2">
      <a href="$pnp4nagios_url?host=$host} . ($servicedesc ? "&srv=$servicedesc" : "") . qq{"><img border=0 src="cid:pnp.png"></a>
    </td>
  </tr>
} : "") . qq{
</table>

</body>}
);

my $rrdimage = MIME::Entity->build(
	Data		=> $rrd,
	Type		=> 'image/png',
	Id		=> '<pnp.png>',
	Encoding	=> 'base64'
) if ($rrd);
$alt->add_part($txt_content);
$alt->add_part($html_content);
$head->add_part($alt);
$head->add_part($rrdimage) if ($rrd);

$head->attach(
	Path		=> $logo,
	Type		=> 'image/png',
	Id		=> '<sblogo.png>',
	Encoding	=> 'base64'
);


open SENDMAIL, '|/usr/sbin/sendmail -t';
$head->print(\*SENDMAIL);
close SENDMAIL;



