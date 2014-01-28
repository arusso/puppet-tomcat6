# == Define: tomcat6::instance
#
# Setup a tomcat6 instance
#
# === Parameters:
#
# [*account*]
#   Account that should own the files
#
# [*ajp_port*]
#   AJP port for this instance
#
# [*http_port*]
#   HTTP port for this instance
#
# [*shutdown_port*]
#   Shutdown port for this instance
#
# [*log_group*]
#   Group that should own the log files
#
# [*redirect_port*]
#   Redirect port of this instance
#
define tomcat6::instance (
  $account = 'UNSET',
  $ajp_port = '8011',
  $http_port = '8080',
  $shutdown_port = '8005',
  $home_group = undef,
  $log_group = undef,
  $redirect_port = '8443',
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
    owner   => $account,
    group   => $account,
    mode    => '2775',
  }

  #######
  # Application Home Resources
  #######
  $app_dirs = [ "/home/${account}/tomcat6-${name}",
                "/home/${account}/tomcat6-${name}/Catalina",
                "/home/${account}/tomcat6-${name}/Catalina/localhost",
                "/home/${account}/tomcat6-${name}/Catalina/lib",
                "/home/${account}/tomcat6-${name}/webapps" ]

  file { $app_dirs:
    ensure  => directory,
    replace => false,
    owner   => $account,
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
    owner  => $account,
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
    owner   => $account,
    group   => $home_group_r,
    mode    => '0664',
  }

  file { "/home/${account}/tomcat6-${name}/conf/server.xml":
    replace => false,
    content => template('tomcat6/server-xml.erb'),
    owner   => $account,
    group   => $home_group_r,
    mode    => '0664',
  }

  #######
  # Service Configuration
  #######
  service { "tomcat6-${name}":
    enable  => true,
    require => File["/etc/init.d/tomcat6-${name}"],
  }
}
