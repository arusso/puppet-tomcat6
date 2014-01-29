# == Class: tomcat6::package
#
# Installs tomcat6
#
class tomcat6::package {
  package { 'tomcat6': ensure => 'installed' }
}
