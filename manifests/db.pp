# Webtrees database connection to remote mysql server
# Requires puppet-mysql
#
class webtrees::db {

  # VARIABLES
  $provisioning = lookup('webtrees::provisioning')  # OS-family specific parameters
  $nx           = lookup('nginx::reverse_proxy')    # Reverse proxy
  $configuration= lookup('webtrees::configuration')         # Host-specific parameters
  $source       = lookup('webtrees::source')        # Host-specific parameters

  # Derived Values
  $version = $source['version']      # Webtrees version
  $download_link = "${source['download_link']}/${version}.tar.gz" # URL for downloading webtrees

  $server_name = $nx['server']['name']                     # Example 'example.com'
  $vhost_dir = "${provisioning['wwwroot']}/${server_name}"  # #xample '/var/www/example.com'
  $webtrees_dir = "webtrees-${version}"  # Webtrees subdirectory
  $www_root = "${vhost_dir}/${webtrees_dir}" # Example '/var/www/example.com/webtrees/'

  $user = $provisioning['user']
  $group = $provisioning['group']

  $webtrees_config = "${www_root}/${configuration['config_file']['path']}" # Configuration File
  $db = lookup('webtrees::configuration')['db']         # Host-specific parameters


  # Install Mysql with php
  include mysql::client
  class { 'mysql::bindings':    php_enable => true,   }

  # Create database on remote server.  Warning: database credentials must match those used in wp-config.php
  @@mysql::db { $db['name']:
    user     => $db['user'],
    password => $db['pass'],
    host     => $::fqdn,  # user from the wordpress-host is granted access to remote database server
    grant    => ['ALL'],
    charset  => ['utf8mb3'],  # same as utf8 but new name in mysql
    tag      => $db['host'],  # to be collected on the database remote host
  }

  # Configure database connection
    concat::fragment {'Webtrees Database Connection':
    target  => $webtrees_config,
    content => epp('webtrees/config_db.epp',{
              'type'         => $db['type'],
              'host'         => $db['host'],
              'port'         => $db['port'],
              'user'         => $db['user'],
              'pass'         => $db['pass'],
              'name'         => $db['name'],
              'table_prefix' => $db['table_prefix'],
    }),
    order   => '20',
  }

}
