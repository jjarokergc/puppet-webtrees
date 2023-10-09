# Webtrees Installation
# Downloads archived version
#
class webtrees::install {
  # VARIABLES
  $provisioning = lookup('webtrees::provisioning')  # OS-family specific parameters
  $configuration= lookup('webtrees::configuration')         # Host-specific parameters
  $source       = lookup('webtrees::source')        # Host-specific parameters

  # Derived Values
  $version = $source['version']      # Webtrees version
  $webtrees_dir = "webtrees-${version}"  # Webtrees subdirectory
  $download_url = "${source['download_link']}/${version}/${webtrees_dir}.zip" # URL for downloading webtrees

  $server_name = $configuration['server']['fqdn']
  $vhost_dir = "${provisioning['wwwroot']}/${server_name}"  # #xample '/var/www/example.com'
  $www_root = "${vhost_dir}/${webtrees_dir}" # Example '/var/www/example.com/webtrees/'

  $user = $provisioning['user']
  $group = $provisioning['group']

  $webtrees_config = "${www_root}/${configuration['config_file']['path']}" # Configuration File

  $base_url = "${$configuration['config_file']['base_url_scheme']}://${server_name}"

  # 1 - INSTALL ARCHIVE
  file { [
      $vhost_dir,               # Example: /var/www/example.com
      $provisioning['wwwroot'], # Example: /var/www
    ]:
      ensure => directory,
      owner  => $user,
      group  => $group,
  }
  package { 'unzip': ensure => installed, } # Required by archive module for zip files
  archive { 'webtrees':
    ensure       => present,
    path         => "/tmp/${webtrees_dir}.zip",
    extract      => true,
    extract_path => $vhost_dir,
    source       => $download_url,
    creates      => $www_root,
    user         => $user,
    group        => $group,
    cleanup      => true,
    require      => File[$vhost_dir],
    notify       => Exec['Rename Webtrees Directory'],
  }
  exec { 'Rename Webtrees Directory': # For convenience, use directory name that includes webtrees version
    cwd         => $vhost_dir,
    command     => ['mv', 'webtrees', $webtrees_dir],
    refreshonly => true,
    user        => $user,
    group       => $group,
    path        => ['/usr/bin', '/usr/sbin',],
  }

  # 2 - CONFIGURE
  # Configuration file
  concat { $webtrees_config:
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0440',
    require => Exec['Rename Webtrees Directory'],
  }
  concat::fragment { 'header':
    target  => $webtrees_config,
    content => "; <?php return; ?>\n\n; PUPPET MANAGED FILE\n\n",
    order   => '01',
  }
  # Base URL detection
  concat::fragment { 'Webtrees Base URL':
    target  => $webtrees_config,
    content => "base_url='${base_url}'\n",
    order   => '10',
  }
  # Pretty url rewrite
  concat::fragment { 'Webtrees Rewrite URL':
    target  => $webtrees_config,
    content => "rewrite_urls='${configuration['config_file']['rewrite_urls']}'\n",
    order   => '11',
  }

  # TBD - See: https://webtrees.net/admin/proxy/
  # Determine whether it is necessary to set IP from proxy
  # Currently, this nginx app server is configured to restore the real IP that is
  # sent by the reverse proxy.  Setting real ip again in config.ini.php may be 
  # redundant or wrong
}
