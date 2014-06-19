# == Define: tomcat6::instance
#
# Setup a tomcat6 instance
#
# === Parameters:
#
# [*account*]
#   (Required) Account that should own the files
#
# [*ajp_port*]
#   AJP port for this instance. Defaults to 8011.
#
# [*home_group*]
#   Group that should own the configuration files in the home directory. If
#   left unset, defaults to $account.
#
# [*home_owner*]
#   Owner that should own the configuration files in the home directory. If
#   left unset, defaults to $account.
#
# [*http_port*]
#   HTTP port for this instance. Defaults to 8080.
#
# [*log_group*]
#   Group that should own the log files. If unset, defaults to $account
#
# [*redirect_port*]
#   Redirect port of this instance. Defaults to 8443.
#
# [*shutdown_port*]
#   Shutdown port for this instance. Defaults to 8005.
#
# [*service_enable*]
#   Service enable state. Should be 'enabled/disabled/ignore'. Default is
#   'enabled'.
#
# [*service_ensure*]
#   Service ensure state. Should be either 'running/stopped/ignore'. Default is
#   'running'
#
define tomcat6::instance (
  $account = 'UNSET',
  $ajp_port = '8011',
  $http_port = '8080',
  $home_owner = undef,
  $home_group = undef,
  $log_group = undef,
  $redirect_port = '8443',
  $shutdown_port = '8005',
  $service_enable = 'enabled',
  $service_ensure = 'running',
) {
  include tomcat6

  if $account == 'UNSET' {
    fail("account must be set for Tomcat6::Instance${::title}]")
  }

  $home_group_r = $home_group ? {
    undef   => $account,
    default => $home_group,
  }

  $log_group_r = $log_group ? {
    undef   => $account,
    default => $log_group,
  }

  $home_owner_r = $home_owner ? {
    undef   => $account,
    default => $home_owner,
  }

  file { "/etc/sysconfig/tomcat6-${name}":
    ensure  => file,
    replace => false,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('tomcat6/sysconfig.erb')
  }

  file { "/etc/init.d/tomcat6-${name}":
    ensure  => link,
    owner   => 'root',
    group   => 'root',
    target  => '/etc/init.d/tomcat6',
    require => Class['tomcat6::package'],
  }

  ######
  # Cache Directories
  ######
  $cache_dirs = [ "/var/cache/tomcat6-${name}",
                  "/var/cache/tomcat6-${name}/temp",
                  "/var/cache/tomcat6-${name}/work" ]
  file { $cache_dirs:
    ensure  => directory,
    owner   => $home_owner_r,
    group   => $home_group_r,
    mode    => '2775',
  }

  #######
  # Application Home Resources
  #######
  $app_dirs = [ "/home/${account}/tomcat6-${name}",
                "/home/${account}/tomcat6-${name}/conf/Catalina",
                "/home/${account}/tomcat6-${name}/lib",
                "/home/${account}/tomcat6-${name}/webapps" ]

  file { $app_dirs:
    ensure  => directory,
    replace => false,
    owner   => $home_owner_r,
    group   => $home_group_r,
    mode    => '2775',
  }

  file { "/var/log/tomcat6-${name}":
    ensure => directory,
    owner  => $account,
    group  => $log_group_r,
    mode   => '2775',
  }

  file { "/home/${account}/tomcat6-${name}/logs":
    ensure  => link,
    owner   => $account,
    group   => $log_group_r,
    mode    => '2775',
    target  => "/var/log/tomcat6-${name}",
  }

  file { "/home/${account}/tomcat6-${name}/bin":
    ensure => link,
    owner  => $home_owner_r,
    group  => $home_group_r,
    mode   => '2775',
    target => '/usr/share/tomcat6/bin',
  }

  #######
  # Initial Configuration Files
  #######
  file { "/home/${account}/tomcat6-${name}/conf":
    replace => false,
    recurse => true,
    purge   => false,
    source  => 'puppet:///modules/tomcat6/app-home/',
    owner   => $home_owner_r,
    group   => $home_group_r,
    mode    => '0644',
  }

  file { "/home/${account}/tomcat6-${name}/conf/server.xml":
    replace => false,
    content => template('tomcat6/server-xml.erb'),
    owner   => $home_owner_r,
    group   => $home_group_r,
    mode    => '0644',
  }

  #######
  # Service Configuration
  #######
  case $service_enable {
    /^enable/,true: { $service_enable_r = true }
    /^disable/,false: { $service_enable_r = false }
    /^ignore|noop$/: { $service_enable_r = undef }
    default: {
      fail("invalid value for service_enable specified. '${service_enable}'")
    }
  }
  case $service_ensure {
    /^run/,true: { $service_ensure_r = true }
    /^stop/,false: { $service_ensure_r = false }
    /^ignore|noop$/: { $service_ensure_r = undef }
    default: {
      fail("invalid value for service_ensure specified. '${service_ensure}'")
    }
  }
  service { "tomcat6-${name}":
    ensure  => $service_ensure_r,
    enable  => $service_enable_r,
    require => File["/etc/init.d/tomcat6-${name}"],
  }
}
