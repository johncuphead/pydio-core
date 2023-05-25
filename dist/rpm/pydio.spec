%define ajaxplorerdir %{_datadir}/ajaxplorer
Name: ajaxplorer
Version:  4.2.0
Release:  1%{?dist}
Summary: Build your own box with AjaXplorer : web RIA, mobile applications, desktop sync

Group: Applications/Publishing
License: AGPL
Vendor: Abstrium SAS
URL: http://ajaxplorer.info/
Source0: http://sourceforge.net/projects/ajaxplorer/files/ajaxplorer/stable-channel/%{version}/ajaxplorer-core-%{version}.zip
Source1: %{name}.conf

BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: php php-xml php-gd
Requires: php-mcrypt

%description
AjaXplorer is a PHP-based browser for managing files on a web server without FTP. Fully loaded
 with file formats preview, extended sharing, multidevice support and access control management
 it is the perfect tool to replace (drop)box and alikes in the enterprise.

%prep

%setup -q -n %{name}-core-%{version}

sed -i 's/"zip"/"rpm"/g' base.conf.php
sed -i 's/AJXP_INSTALL_PATH."\/conf"/"\/etc\/ajaxplorer"/g' base.conf.php

sed -i 's/AJXP_DATA_PATH."\/cache"/"\/var\/cache\/ajaxplorer"/g' conf/bootstrap_context.php
sed -i 's/AJXP_INSTALL_PATH."\/data\/cache"/"\/var\/cache\/ajaxplorer"/g' conf/bootstrap_context.php
sed -i 's/AJXP_INSTALL_PATH."\/data"/"\/var\/lib\/ajaxplorer"/g' conf/bootstrap_context.php
sed -i 's/\/\/ define("AJXP_FORCE_LOGPATH/define("AJXP_FORCE_LOGPATH/g' conf/bootstrap_context.php

%build

%install
rm -rf %{buildroot}

# copy application
install -d %{buildroot}%{ajaxplorerdir}
cp -pr . %{buildroot}%{ajaxplorerdir}

# apache conf
mkdir -p %{buildroot}%{_sysconfdir}/httpd/conf.d
cp -pr %SOURCE1 %{buildroot}%{_sysconfdir}/httpd/conf.d/%{name}.conf

# move conf to /etc
mv %{buildroot}%{ajaxplorerdir}/conf %{buildroot}%{_sysconfdir}/%{name}

# move data to /var
mkdir -p %{buildroot}%{_localstatedir}/lib
mv %{buildroot}%{ajaxplorerdir}/data %{buildroot}%{_localstatedir}/lib/%{name}

# move cache to /var/cache
mkdir -p %{buildroot}%{_localstatedir}/cache
mv %{buildroot}%{_localstatedir}/lib/%{name}/cache %{buildroot}%{_localstatedir}/cache/%{name}

# move logs to /var/log
mkdir -p %{buildroot}%{_localstatedir}/log
mv %{buildroot}%{_localstatedir}/lib/%{name}/logs %{buildroot}%{_localstatedir}/log/%{name}

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{ajaxplorerdir}
%{_sysconfdir}/%{name}/.htaccess
%config(noreplace) %{_sysconfdir}/%{name}/*
%config(noreplace) %{_sysconfdir}/httpd/conf.d/%{name}*.conf
%attr(755,apache,apache) %{_localstatedir}/lib/%{name}
%dir %attr(755,apache,apache) %{_localstatedir}/cache/%{name}
%{_localstatedir}/cache/%{name}/.htaccess
%{_localstatedir}/cache/%{name}/index.html
%dir %attr(755,apache,apache) %{_localstatedir}/log/%{name}
%{_localstatedir}/log/%{name}/.htaccess
%{_localstatedir}/log/%{name}/*

%post
if [ -f "%{_localstatedir}/cache/%{name}/plugins_cache.ser" ]
then
    # Upgrading an existing install
    rm -f %{_localstatedir}/cache/%{name}/plugins_*.ser
    if [ ! -f "%{_localstatedir}/cache/%{name}/first_run_passed" ]
    then
        touch %{_localstatedir}/cache/%{name}/first_run_passed
    fi
fi


%changelog
* Wed Jun 01 2013 Charles du Jeu <charles@ajaxplorer.info> - 5.0.0-1
- Add post install script

* Wed Jun 27 2012 Charles du Jeu <charles@ajaxplorer.info> - 4.2.0-1
- Update spec file, integrate in the phing automated process
- Replace the patch by sed commands (more line changes proof)

* Sun Dec 18 2011 Mathieu Baudier <mbaudier@argeo.org> - 4.0.0-1
- AjaXplorer v4 release

* Wed Dec 07 2011 Mathieu Baudier <mbaudier@argeo.org> - 3.3.6-0_20111206_2620
- Fix issue with logs paths
- Move VERSION and README back to conf

* Fri Dec 02 2011 Mathieu Baudier <mbaudier@argeo.org> - 3.3.5-1
- Initial packaging
