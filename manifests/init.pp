# Install webtrees, php and nginx webserver
#
# Class: profile::webtrees
#
#
class webtrees {
  # 1 - WEBTREES DOWNLOAD
  class { 'webtrees::install': }
  # 2 - PHP INSTALL
  class { 'webtrees::php': }
  # 3 - DATABASE CONNECTION
  class { 'webtrees::db': }
  # 4 - NGINX WEB SERVER
  class { 'webtrees::nginx': }
}
