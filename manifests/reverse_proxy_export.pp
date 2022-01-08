# Webtrees Reverse Proxy Configuration
# Configuration data in hiera
# Exports resources to reverse proxy server
#
class webtrees::reverse_proxy_export{

# VARIABLES
  $nx = lookup('nginx::reverse_proxy')
  $server_name = $nx['server']['name']
  $virtualhost_url = "http://${::ipaddress}"

# 1 - NGINX SERVER, LETSENCRYPT, MODSECURITY, CACHING
  include profile::nginx::reverse_proxy_export

# 2 - Webtrees-specific locations
# Static files have versions in their URLs, and can be cached indefinitely.
  @@nginx::resource::location { "Static Files ${server_name}:SSL" :
    ensure              => present,
    location            => '/webtrees/public',
    server              => "revproxy.${server_name}",
    expires             => '365d',
    ssl                 => true,
    ssl_only            => true,
    index_files         => [],
    location_cfg_append => {
                          'access_log' => 'off',
                      },
  }
# Restricted locations
  @@nginx::resource::location { "Restricted Files ${server_name}:SSL" :
    ensure              => present,
    location            => '~ /webtrees/(data|app|modules|resources|vendor|conf|bin|inc)/',
    server              => "revproxy.${server_name}",
    limit_zone          => 'exploit_zone',          # No legitimate access to this location
    ssl                 => true,
    ssl_only            => true,
    index_files         => [],
    location_deny       => ['all'],
    location_cfg_append => {
                          'log_not_found' => 'on',  #Log the error for use by Fail2Ban
                          'return'        => '404',
                          },
  }

}
