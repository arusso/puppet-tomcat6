require 'spec_helper'

describe( 'tomcat6::package', :type => :class ) do 
  it do
    should contain_package('tomcat6').with_ensure('installed')
  end
end
