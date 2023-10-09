# Puppet Module for Webtrees

This module installs and configures Webtrees.

The development repository is located at: <https://gitlab.jaroker.org>. 
A mirror repository is pushed to: <https://github.com/jjarokergc/puppet-webtrees>

## Architecture

The application is served by nginx and is designed to be used behind a reverse proxy that provides SSL offloading and caching.  Hiera is used data lookup, which specifies source location (and version) for downloading, database configuration, nginx configuration and php setup.

 Tested Configuration

* Webtrees 2.1.17
* nginx 1.24.0
* php 8.1.2
* MariaDB 10.6.12, operating on a remote server

## Requirements

Puppetfile.r10k

``` puppet
mod 'puppetlabs-concat', '9.0.0'
mod 'puppetlabs-stdlib', '9.3.0'
mod 'puppetlabs-vcsrepo', '6.1.0'
mod 'puppet-nginx', '5.0.0'
mod 'puppet-php', '10.0.0'
```

## Usage Example



Download webtrees, install PHP, set up the database connection and install the local web server:

``` puppet            
    include webtrees
```

## Hiera Data

Configuration parameters are defined in data/common.yaml

## Author

Jon Jaroker