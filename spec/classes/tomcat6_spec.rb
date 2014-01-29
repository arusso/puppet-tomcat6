require 'spec_helper'

describe( 'tomcat6', :type => :class ) do 
  it do
    should contain_tomcat6__package
  end
end
