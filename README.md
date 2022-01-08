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

  include profile::base_configuration  # Creates admin user accounts, 
                                       # installs basic O/S packages

  # Install Webtrees
  include profile::webtrees

  # Export configuration for NGINX reverse proxy
  include ::webtrees::reverse_proxy_export  # Exports Server and Location directives to the 
                                            # Nginx reverse proxy

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

## Hiera Data Example

``` yaml
# Webtrees Data
# /etc/puppetlabs/code/environments/production/data/nodes/webtrees.domain.yaml
---
nginx::reverse_proxy:
  server:
    name: 'webtrees.example.com'
    fqdn: ['webtrees.example.com']        # server name
    client_max_body_size: '80m'        # allowed size of uploaded files
  location:
    modsecurity:
      on_off: 'on'                    # 'on' or 'off' to enable modsecurity in ngnix
      config_filename: "webtrees.conf"  # configuration file must exist in /etc/nginx/modsec
webtrees::configuration:
  config_file:
    path : 'data/config.ini.php'      # Webtrees configuration file
    base_url: 'https://webtrees.example.com' # Specify URL for webtrees site
    rewrite_urls: '1'                 # Pretty URLs. NGINX compatible config required.
  db:
    name: 'wt'
    user: 'wtuser'
    pass: 'wtpass'
    host: 'db.example.org'
    port: 3306
    table_prefix: 'wt_'
    type: 'mysql' # Database type
  phpini: # php.ini settings
    tz: 'America/New_York'   # Time Zone
    mem_limit: '128M'
    cpu_time: '80' # Max Execution Time
webtrees::source: 
  # See: https://github.com/fisharebest/webtrees/releases
  version: "2.0.19"
  download_link: 'https://github.com/fisharebest/webtrees/archive/refs/tags'

# Webtrees PHP debug logging level.  Normal is 'notice'
php::fpm::config::log_level: 'error'
webtrees::php: # php.ini configuration
  logging_mode: 'production' # See module data. 'production' or 'debugging'
```

## Author

Jon Jaroker
devops@jaroker.com
