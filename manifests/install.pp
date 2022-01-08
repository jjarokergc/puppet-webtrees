# Webtrees Installation
# Downloads archived version
#
class webtrees::install{

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



  # 1 - INSTALL ARCHIVE
  file { [
          $vhost_dir,               # Example: /var/www/example.com
          $provisioning['wwwroot'], # Example: /var/www
          ]:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }
  archive { 'webtrees':
    ensure       => present,
    path         => "/tmp/${webtrees_dir}.tar.gz",
    extract      => true,
    extract_path => $vhost_dir,
    source       => $download_link,
    creates      => $www_root,
    user         => $user,
    group        => $group,
    cleanup      => true,
    require      => File[$vhost_dir],
  }

  # 2 - CONFIGURE
  # Configuration file
  concat {$webtrees_config:
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0440',
  }
  concat::fragment {'header':
    target  => $webtrees_config,
    content => "; <?php return; ?>\n\n; PUPPET MANAGED FILE\n\n",
    order   => '01',
  }
  # Base URL detection
  concat::fragment {'Webtrees Base URL':
    target  => $webtrees_config,
    content => "base_url='${configuration['config_file']['base_url']}'\n",
    order   => '10',
  }
  # Pretty url rewrite
    concat::fragment {'Webtrees Rewrite URL':
    target  => $webtrees_config,
    content => "rewrite_urls='${configuration['config_file']['rewrite_urls']}'\n",
    order   => '11',
  }

}
