%define debug_package %{nil}

Summary:	OKConfig nrpe base configuration package
Name:		nagios-okconfig-nrpe
Version:	0.0.2
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
install -D -p -m 0755 usr/lib64/nagios/plugins/check_procs.sh %{_libdir}/nagios/plugins/check_procs.sh


%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc README
%config(noreplace) %{_sysconfdir}/nrpe.d/ok-bundle.cfg

%changelog
* Wed Mar 14 2012 Pall Sigurdsson <palli@opensource.is> 0.0.2-1
- new package built with tito

* Tue Feb 14 2012  Tomas Edwardsson <tommi@opensource.is> 0.0.1-2
- Initial RPM packaging

