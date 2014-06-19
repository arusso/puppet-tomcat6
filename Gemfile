source 'https://rubygems.org'

if ENV.key?('PUPPET_VERSION')
  puppetversion = "#{ENV['PUPPET_VERSION']}"
 else
   puppetversion = "~> 2.7.0"
end

gem 'rake'
gem 'puppet-lint'
# we need to lock rspec to 2.x releases until rspec-puppet is updated to
# support rspec3. That is being tracked in here:
#   https://github.com/rodjek/rspec-puppet/pull/204
gem 'rspec', '~> 2.0'
gem "rspec-puppet", :git => 'https://github.com/rodjek/rspec-puppet.git'
gem 'puppet', puppetversion
gem 'puppetlabs_spec_helper'
