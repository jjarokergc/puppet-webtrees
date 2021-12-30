# Puppet Module for Webtrees

## Architecture
This webtrees application is hosted by NGINX and is designed to be behind a reverse proxy.  The reverse proxy provides SSL offloading.

## Requirements
Puppetfile.r10k
```
mod 'puppetlabs-concat', '7.1.1'
mod 'puppetlabs-stdlib', '8.1.0'
mod 'puppetlabs-vcsrepo', '5.0.0'
mod 'puppet-nginx', '3.3.0'
mod 'puppet-php', '8.0.2'
```
## Usage Example

manifests/site.pp
```
node 'webtrees.datacenter'{                 
  include role::app::webtrees_server
}
```

site/role/app/webtrees_server.pp
```
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
```
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