# Puppet Module for Webtrees

The development repository is located at: <https://gitlab.jaroker.org>

A mirror repository is pushed to: <https://github.com/jjarokergc/puppet-webtrees>

## Architecture

This dokuwiki application is hosted with NGINX and is designed to be behind a reverse proxy.  The reverse proxy provides SSL offloading, caching and a ModSecurity firewall.

The puppet module uses hiera for data lookup, which specifies source location (and version) for downloading, database configuration, nginx configuration and php setup.

 Tested Configuration

* Webtrees 2.0.19
* nginx 1.20.2
* php 7.4.3
* mysql 8.0.27, operating as a remote server
* Linux 5.11.22-7, operating as a PVE container on a Proxmox host

## Requirements

Puppetfile.r10k

``` puppet
mod 'puppetlabs-concat', '7.1.1'
mod 'puppetlabs-stdlib', '8.1.0'
mod 'puppetlabs-vcsrepo', '5.0.0'
mod 'puppet-nginx', '3.3.0'
mod 'puppet-php', '8.0.2'
```

## Usage Example

manifests/site.pp

``` puppet
node 'webtrees.datacenter'{                 
  include role::app::webtrees_server
}
```

site/role/app/webtrees_server.pp

``` puppet
# Webtrees Server Role
# Webtrees profile behind an nginx reverse proxy
#
# Class: role::app::webtrees_server
#
class role::app::webtrees_server {

  include profile::base_configuration

  # Install Webtrees
  include profile::webtrees

  # Export configuration for NGINX reverse proxy
  include ::webtrees::reverse_proxy_export

}
```

site/profile/webtrees.pp

``` puppet
# Install webtrees, php and nginx webserver
#
# Class: profile::webtrees
#
#
class profile::webtrees {

  # 1 - WEBTREES DOWNLOAD
  class {'::webtrees::install':}
  # 2 - PHP INSTALL
  class {'::webtrees::php':}
  # 3 - DATABASE CONNECTION
  class {'::webtrees::db':}
  # 4 - NGINX WEB SERVER
  class {'::webtrees::nginx':}
}
```

## Author

Jon Jaroker
devops@jaroker.com
