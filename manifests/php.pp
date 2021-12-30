# Install php for webtrees
# Requires puppet-php module
class webtrees::php (
){

  # VARIABLES
  $provisioning = lookup('webtrees::provisioning')  # OS-specific parameters
  $nx           = lookup('nginx::reverse_proxy')    # Reverse proxy
  $configuration= lookup('webtrees::configuration')         # Host-specific parameters
  $source       = lookup('webtrees::source')        # Host-specific parameters
  $php          = lookup('webtrees::php')
  $fpm          = lookup('webtrees::fpm_pools')
  # Derived Values
  $user = $provisioning['user']
  $group = $provisioning['group']
  $socket = $provisioning['php-fpm']['sock']        # PHP-fpm Config

  # PHP Settings
  $lm = $php['logging_mode']  # Selects the type of logging to configure in php.ini
  $php_general = $php['general'] # General settings
  $php_logging = $php[$lm]       # Logging-mode specific settings
  $php_settings = deep_merge($php_general, $php_logging) # Settings for php.ini

  # Logging 
  if $fpm[$lm]['accesslog'] != '' { # Hiera data has access log specified
    $access_log = $fpm[$lm]['accesslog']
    file {$access_log:
      ensure  => present,
      owner   => $user,
      group   => $group,
      mode    => '0660',
      require => Class['::php'],
    }
  } else {
    $access_log = undef
  }
  if $fpm[$lm]['errorlog'] != '' { # Hiera data has error log specified
    $error_log = $fpm[$lm]['errorlog']
    file {$error_log:
      ensure  => present,
      owner   => $user,
      group   => $group,
      mode    => '0660',
      require => Class['::php'],
      }
    $phpfpm_flag        = {'display_errors' => 'on',   }
    $phpfpm_admin_value = {'error_log'      => $error_log, }
    $phpfpm_admin_flag  = {'log_errors'     => 'on',   }
  } else {
    $phpfpm_flag        = undef
    $phpfpm_admin_value = undef
    $phpfpm_admin_flag  = undef

  }

  # Install PHP and PHP-XML for NGINX
  file {$socket:
    owner   => $user,
    group   => $group,
    require => Class['::php'],
  }
  class{'::php':
    ensure     => present,
    fpm        => true,
    dev        => false,
    composer   => false,
    pear       => false,
    phpunit    => false,
    settings   => $php_settings,
    fpm_pools  => {
      'www' => {
        'catch_workers_output'      => $fpm[$lm]['catch_workers_outpuet'],
        'access_log'                => $access_log,
        'php_flag'                  => $phpfpm_flag,
        'php_admin_value'           => $phpfpm_admin_value,
        'php_admin_flag'            => $phpfpm_admin_flag,
        'listen'                    => $socket,
        'listen_owner'              => $user,
        'listen_group'              => $group,
        'listen_backlog'            => 511,
        'pm'                        => 'dynamic',
        'pm_max_children'           => 80,
        'pm_max_requests'           => 0,
        'pm_max_spare_servers'      => 60,
        'pm_min_spare_servers'      => 10,
        'pm_start_servers'          => 20,
        'request_terminate_timeout' => 0,
          },
        },
    pool_purge => true,
    extensions => {
            'curl'     => {},
            'intl'     => {},
            'mbstring' => {},
            'gd'       => {},
            'mysql'    => {},
            'xml'      => {},
            'zip'      => {},
              },
  }

}
