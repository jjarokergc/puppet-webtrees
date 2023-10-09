# Configure NGINX server with php for Webtrees
# Requires nginx package
# Servers webtrees on socket
# An older PHP version can be specified to allow data migration from older versions of webtrees
#
class webtrees::nginx {
  # VARIABLES
  $provisioning = lookup('webtrees::provisioning')  # OS-family specific parameters
  $configuration= lookup('webtrees::configuration')         # Host-specific parameters
  $source       = lookup('webtrees::source')        # Host-specific parameters

  # Derived Values
  $version = $source['version']      # Webtrees version
  $download_link = "${source['download_link']}/${version}.tar.gz" # URL for downloading webtrees

  $server_params = $configuration['server_params']  # Hash of paramters used by nginx server class
  $server_urls = $configuration['server']['urls'] # Array of urls is merged with common.yaml 
  $server_name = $configuration['server']['fqdn']
  $vhost_dir = "${provisioning['wwwroot']}/${server_name}"  # #xample '/var/www/example.com'
  $webtrees_dir = "webtrees-${version}"  # Webtrees subdirectory
  $www_root = "${vhost_dir}/${webtrees_dir}" # Example '/var/www/example.com/webtrees/'

  $user = $provisioning['user']
  $group = $provisioning['group']
  $socket = $provisioning['php-fpm']['sock']        # PHP-fpm Config

  # NGINX WEB SERVER
  class { 'nginx':
    # Security precaution: don't show nginx version number
    server_tokens    => 'off',
    proxy_set_header => []   # Disable proxy params on this nginx instance
  }
  nginx::resource::server { $server_name:
    server_name => $server_urls,
    www_root    => $www_root,
    require     => Archive['webtrees'],
    *           => $server_params,
  }

  nginx::resource::location { '/':
    server        => $server_name,
    index_files   => [],
    rewrite_rules => ['^ /index.php last'], # Rewrite all other requests onto the webtrees front-controller.
  }
  nginx::resource::location { '= /index.php':# webtrees runs from this one script.
    server        => $server_name,
    index_files   => [],
    include       => ['fastcgi_params'],
    fastcgi_param => { 'SCRIPT_FILENAME' => '$document_root$fastcgi_script_name' },
    fastcgi       => "unix:${socket}",
  }
  nginx::resource::location { '/public':
    server      => $server_name,
    index_files => [],
    expires     => 'max',
  }
}
