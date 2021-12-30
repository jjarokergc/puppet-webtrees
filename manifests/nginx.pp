# Configure NGINX server with php for Webtrees
# Requires nginx package
# Servers webtrees on socket
# An older PHP version can be specified to allow data migration from older versions of webtrees
#
class webtrees::nginx {

  # VARIABLES
  $provisioning = lookup('webtrees::provisioning')  # OS-family specific parameters
  $nx           = lookup('nginx::reverse_proxy')    # Reverse proxy
  $configuration= lookup('webtrees::configuration')         # Host-specific parameters
  $source       = lookup('webtrees::source')        # Host-specific parameters

  # Derived Values
  $version = $source['version']      # Webtrees version
  $download_link = "${source['download_link']}/${version}.tar.gz" # URL for downloading webtrees

  $server_name = $nx[server][fqdn]                     # Example 'example.com'
  $vhost_dir = "${provisioning['wwwroot']}/${server_name}"  # #xample '/var/www/example.com'
  $webtrees_dir = "webtrees-${version}"  # Webtrees subdirectory
  $www_root = "${vhost_dir}/${webtrees_dir}" # Example '/var/www/example.com/webtrees/'

  $user = $provisioning['user']
  $group = $provisioning['group']
  $socket = $provisioning['php-fpm']['sock']        # PHP-fpm Config


  # NGINX WEB SERVER
  class {'::nginx':}
  nginx::resource::server { $server_name:
    server_name          => [$server_name, $::fqdn],
    use_default_location => false,
    www_root             => $www_root,
    index_files          => [],
    client_max_body_size => $nx[server][client_max_body_size],
    require              => Archive['webtrees'],
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
      fastcgi_param => {'SCRIPT_FILENAME' => '$document_root$fastcgi_script_name'},
      fastcgi       => "unix:${socket}",
      }
  nginx::resource::location { '/public':
    server      => $server_name,
    index_files => [],
    expires     => 'max',
  }
}
