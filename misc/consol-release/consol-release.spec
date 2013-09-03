Name:           consol-release       
Version:        1.2
Release:        1%{dist}
Summary:        This package contains the Consol Labs packages for redhat based systems.

Group:          System Environment/Base 
License:        GPLv2

# This is a Red Hat maintained package which is specific to
# our distribution.  Thus the source is only available from
# within this srpm.
URL:            http://labs.consol.de/repo/
Source0:        consol-release-%{version}.tar.gz	

BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildArch:     noarch
%if 0%{?rhel}
Requires:      redhat-release
%endif

%if 0%{?fedora}
Requires:      fedora-release
%endif

%description
This package contains consol labs packages for redhat based systems.

%prep
%setup -q 
#install -pm 644 %{SOURCE0} .

%build


%install
rm -rf $RPM_BUILD_ROOT

#GPG Key
#install -Dpm 644 %{SOURCE0} \
#    $RPM_BUILD_ROOT%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6

# yum
# yum
install -dm 755 $RPM_BUILD_ROOT%{_sysconfdir}/yum.repos.d
install -m 755 labs.repo $RPM_BUILD_ROOT%{_sysconfdir}/yum.repos.d

#DISTRO=unknown
#test -f /etc/redhat-release && DISTRO=rhel
#test -f /etc/fedora-release && DISTRO=fedora

#echo DISTRO=$DISTRO
#sed "s/_DIST_/$DISTRO/g" ok.repo > $RPM_BUILD_ROOT%{_sysconfdir}/yum.repos.d/ok.repo


%clean
rm -rf $RPM_BUILD_ROOT

%post
# Not needed for el6 as sources has been removed
#echo "# epel repo -- added by epel-release " \
#    >> %{_sysconfdir}/sysconfig/rhn/sources
#echo "yum epel http://download.fedora.redhat.com/pub/epel/%{version}/\$ARCH" \
#    >> %{_sysconfdir}/sysconfig/rhn/sources

%postun 
#sed -i '/^yum\ epel/d' %{_sysconfdir}/sysconfig/rhn/sources
#sed -i '/^\#\ epel\ repo\ /d' %{_sysconfdir}/sysconfig/rhn/sources


%files
%defattr(-,root,root,-)
%doc GPL
%config(noreplace) /etc/yum.repos.d/*
#/etc/pki/rpm-gpg/*


%changelog
* Thu Aug 08 2013 Your Name <you@example.com> 1.2-1
- new package built with tito

* Thu Aug 08 2013 Pall Sigurdsson <palli@opensource.is> 1.1-1
- new package built with tito

* Sun May 19 2013 Pall Sigurdsson <palli@opensource.is> 
- Initial Package
