%define debug_package %{nil}

Summary:	OKConfig nrpe base configuration package
Name:		nagios-okconfig-nrpe
Version:	0.0.5
Release:	1%{?dist}
License:	GPLv2+
Group:		Applications/System
URL:		http://opensource.ok.is/trac/wiki/Nagios-OKConfig
Source0:	http://opensource.ok.is/trac/browser#nrpe-client/linux/%{name}-%{version}.tar.gz
Requires:	nrpe nagios-okplugin-check_yum nagios-plugins-load nagios-plugins-procs  nagios-plugins-swap
Requires:	nagios-plugins-check_cpu	
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Packager:	Tomas Edwardsson <tommi@ok.is>
BuildArch:	noarch


%description
Default configuration file for base monitoring of a linux system

%prep
%setup -q

%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_sysconfdir}/nrpe.d
sed "s^/usr/lib64^%{_libdir}^g" etc/nrpe.d/ok-bundle.cfg >  %{buildroot}%{_sysconfdir}/nrpe.d/ok-bundle.cfg
sed -i "s^/usr/lib64^%{_libdir}^g" usr/lib64/nagios/plugins/check_procs.sh
install -D -p -m 0755 usr/lib64/nagios/plugins/check_procs.sh %{buildroot}%{_libdir}/nagios/plugins/check_procs.sh
install -D -p -m 0755 usr/lib64/nagios/plugins/get_ifoperstate.sh %{buildroot}%{_libdir}/nagios/plugins/get_ifoperstate.sh


%clean
rm -rf %{buildroot}

%post
/sbin/service nrpe status && /sbin/service nrpe reload

%files
%defattr(-,root,root,-)
%doc README
%config(noreplace) %{_sysconfdir}/nrpe.d/ok-bundle.cfg
%{_libdir}/nagios/plugins/check_procs.sh
%{_libdir}/nagios/plugins/get_ifoperstate.sh

%changelog
* Wed Jun 05 2013 Tomas Edwardsson <tommi@tommi.org> 0.0.5-1
- Ignore non directories, they are not network interfaces (tommi@tommi.org)

* Wed Jun 05 2013 Tomas Edwardsson <tommi@tommi.org> 0.0.4-1
- Disabled reload for nrpe not running (tommi@tommi.org)
- Added get_ifoperstate to get up/down/unknown for network device links
  (tommi@tommi.org)
- Added nrpe reload to post section (tommi@tommi.org)

* Wed Mar 14 2012 Pall Sigurdsson <palli@opensource.is> 0.0.3-1
- typo fixed in spec file (palli@opensource.is)
- typo fixed in spec file (palli@opensource.is)
- typo fixed in spec file (palli@opensource.is)

* Wed Mar 14 2012 Pall Sigurdsson <palli@opensource.is> 0.0.2-1
- new package built with tito

* Tue Feb 14 2012  Tomas Edwardsson <tommi@opensource.is> 0.0.1-2
- Initial RPM packaging

