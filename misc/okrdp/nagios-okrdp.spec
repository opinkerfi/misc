Name:		nagios-okrdp
Version:	1.0
Release:	1%{?dist}
Summary:	Sends Nagios host/service status to a remote OKRDP host

Group:		Applications/System
License:	GPLv3
URL:		https://opensource.ok.is/source
Source0:	%{name}-%{version}.tar.gz

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch



%description
Sends Nagios host/service status to a remote OKRDP host. Typically used to
send status from a nagios host to a central server.

%clean
rm -rf $RPM_BUILD_ROOT

%prep
%setup -q



%build
true


%install
test "x$RPM_BUILD_ROOT" != "x" && rm -rf $RPM_BUILD_ROOT
install -D -m 600 okrdp.conf $RPM_BUILD_ROOT/%{_sysconfdir}/okrdp.conf
install -D -m 755 okrdp-relay $RPM_BUILD_ROOT/%{_bindir}/okrdp-relay

%files
%doc README.md gpl-3.0.txt
%{_sysconfdir}/okrdp.conf
%{_bindir}/okrdp-relay



%changelog
* Thu Feb 28 2013 Tomas Edwardsson <tommi@tommi.org> 1.8-1
- 