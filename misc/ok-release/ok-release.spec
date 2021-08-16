Name:           ok-release       
Version:        13
Release:        1%{dist}
Summary:        This package contains the OK packages for redhat based systems.

Group:          System Environment/Base 
License:        GPLv2

# This is a Red Hat maintained package which is specific to
# our distribution.  Thus the source is only available from
# within this srpm.
URL:            http://download.fedora.redhat.com/pub/epel
Source0:        ok-release-%{version}.tar.gz	

BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildArch:     noarch
%if 0%{?rhel}
Requires:      redhat-release
%endif

%if 0%{?fedora}
Requires:      fedora-release
%endif

%description
This package contains the OK packages for redhat based systems.

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

DISTRO=unknown
test -f /etc/redhat-release && DISTRO=rhel
test -f /etc/fedora-release && DISTRO=fedora

echo DISTRO=$DISTRO
sed "s/_DIST_/$DISTRO/g" ok.repo > $RPM_BUILD_ROOT%{_sysconfdir}/yum.repos.d/ok.repo


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
* Fri Mar 14 2014 Tomas Edwardsson <tommi@tommi.org> 12-1
- Added fedora 20 releaser

* Sun May 19 2013 Pall Sigurdsson <palli@opensource.is> 
- More generic rpm packages. Handles more distros. (palli@opensource.is)

* Sat May 26 2012 Tomas Edwardsson <tommi@tommi.org> 10-1
- Fixed title to include Testing (tommi@tommi.org)

* Sat May 26 2012 Tomas Edwardsson <tommi@tommi.org> 9-1
- dist added to release in package name (tommi@tommi.org)

* Sat May 26 2012 Tomas Edwardsson <tommi@tommi.org> 8-1
- working build

* Tue May 23 2011 Tomas Edwardsson <tommi@opensource.is> - 6-5
- Re-done from RHEL6 EPEL release

* Tue Oct 12 2010 Michael Stahnke <stahnma@fedoraproject.org> - 6-5
- Fix bug #627611

* Wed Aug 11 2010 Seth Vidal <skvidal at fedoraproject.org> - 6-4
- conflict fedora-release

* Fri Jul 09 2010 Dennis Gilmore <dennis@ausil.us> - 6-3
- use metalink urls not mirrorlist ones

* Tue Apr 27 2010 Dennis Gilmore <dennis@ausil.us> - 6-1
- setup for EL-6 
- new key

* Tue Feb 24 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 6-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_11_Mass_Rebuild

* Thu Jul 17 2008 Tom "spot" Callaway <tcallawa@redhat.com> - 6.1
- fix license tag

* Sun Mar 25 2007 Michael Stahnke <mastahnke@gmail.com> - 6-0
- Bumped in devel to RHEL 6. (We can dream).

* Sun Mar 25 2007 Michael Stahnke <mastahnke@gmail.com> - 4-4
- Changed description again

* Sun Mar 25 2007 Michael Stahnke <mastahnke@gmail.com> - 4-3
- Removed cp in postun
- Removed the file epel-release - provides no value
- Removed dist tag as per review bug #233236
- Changed description

* Mon Mar 14 2007 Michael Stahnke <mastahnke@gmail.com> - 4-2
- Fixed up2date issues. 

* Mon Mar 12 2007 Michael Stahnke <mastahnke@gmail.com> - 4-1
- Initial Package
