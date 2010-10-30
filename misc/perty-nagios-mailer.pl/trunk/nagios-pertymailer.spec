%define debug_package %{nil}

Summary:	Pretty Email Notifications for Nagios
Name:		nagios-pertymailer
Version:	0.0.2
Release:	1%{?dist}
License:	GPLv2+
Group:		Applications/System
URL:		http://opensource.is/trac/wiki/nagios-pertymailer
Source0:	http://opensource.ok.is/trac/browser/misc/nagios-pertymailer/releases/nagios-pertymailer-%{version}.tar.gz
Requires:	perl-MIME-tools,perl-MIME-Lite
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Packager:	Pall Sigurdsson <palli@opensource.is>


%description
Pretty Email Notifications for Nagios 

%prep
%setup -q
perl -pi -e "s|/usr/lib|%{_libdir}|g" perty-nagios-mailer.pl

%build


%install
rm -rf %{buildroot}
install -D -p -m 0755 perty-nagios-mailer.pl  %{buildroot}%{_libdir}/nagios/plugins/perty-nagios-mailer.pl

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc TODO commands.cfg-example
#%{_libdir}/nagios/plugins/*
#o/etc/nrpe.d/check_hpacucli.cfg
%{_libdir}/nagios/plugins/perty-nagios-mailer.pl

%changelog
* Mon Mar  1 2010  Pall Sigurdsson <palli@opensource.is> 0.1-1
- Initial packaging
