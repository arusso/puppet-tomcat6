require 'spec_helper'

describe( 'tomcat6::instance', :type => :define) do 
  context "instance 'someapp'" do
    let(:title) { 'someapp' }
    #
    ## Test our no-parameter case, which should throw an error
    context "with no parameters" do
      it do
        expect {
          should contain_file('/etc/sysconfig/tomcat6-someapp')
        }.to raise_error(Puppet::Error,/account must be set/)
      end
    end

    #
    ## Test when we pass a valid account name
    context "with account='someapp_account'" do
      let(:params) { { 'account' => 'someapp_account' } }
      it do
        # ensure sysconfig file for this instance is setup
        should contain_file('/etc/sysconfig/tomcat6-someapp').with({
          'ensure' => 'file',
          'replace' => false,
          'owner' => 'root',
          'group' => 'root',
          'mode' => '0444',
          'content' => /\/home\/someapp_account\/tomcat6-someapp/
        })

        # ensure an init script is setup for this instance
        should contain_file('/etc/init.d/tomcat6-someapp').with({
          'ensure' => 'link',
          'owner' => 'root',
          'group' => 'root',
          'target' => '/etc/init.d/tomcat6',
          'require' => 'Class[Tomcat6::Package]',
        })

        # ensure our application dirs are setup
        app_dirs = [
          '/home/someapp_account/tomcat6-someapp',
          '/home/someapp_account/tomcat6-someapp/conf/Catalina',
          '/home/someapp_account/tomcat6-someapp/webapps',
          '/home/someapp_account/tomcat6-someapp/lib',
        ]
        app_dirs.each do |ad|
          should contain_file(ad).with({
            'ensure' => 'directory',
            'replace' => false,
            'owner' => 'someapp_account',
            'group' => 'someapp_account',
            'mode' => '2775',
          })
        end

        # ensure our log dir is setup
        should contain_file('/var/log/tomcat6-someapp').with({
          'ensure' => 'directory',
          'owner' => 'someapp_account',
          'group' => 'someapp_account',
          'mode' => '2775',
        })

        # setup a symlink to our log dir in the app home dir
        should contain_file('/home/someapp_account/tomcat6-someapp/logs').with({
          'ensure' => 'link',
          'owner' => 'someapp_account',
          'group' => 'someapp_account',
          'mode' => '2775',
          'target' => '/var/log/tomcat6-someapp',
        })

        # setup a symlink to our bin dir in the app home dir
        should contain_file('/home/someapp_account/tomcat6-someapp/bin').with({
          'ensure' => 'link',
          'owner' => 'someapp_account',
          'group' => 'someapp_account',
          'mode' => '2775',
          'target' => '/usr/share/tomcat6/bin',
        })

        # setup some additional links
        should contain_file('/home/someapp_account/tomcat6-someapp/temp').with({
          'ensure' => 'link',
          'target' => '/var/cache/tomcat6-someapp/temp',
        })
        should contain_file('/home/someapp_account/tomcat6-someapp/work').with({
          'ensure' => 'link',
          'target' => '/var/cache/tomcat6-someapp/work',
        })

        # ensure our cache directory is setup properly
        should contain_file('/var/cache/tomcat6-someapp').with({
          'ensure' => 'directory',
          'owner' => 'someapp_account',
          'group' => 'someapp_account',
          'mode' => '2775',
        })

        # check for the initial setup of the app home dir
        should contain_file('/home/someapp_account/tomcat6-someapp/conf').with({
         'replace' => false,
         'recurse' => true,
         'purge' => false,
         'source' => 'puppet:///modules/tomcat6/app-home/',
         'owner' => 'someapp_account',
         'group' => 'someapp_account',
         'mode' => '0644',
        })

        # check for our initial config
        config_file = '/home/someapp_account/tomcat6-someapp/conf/server.xml'
        should contain_file(config_file).with({
          'replace' => false,
          'owner' => 'someapp_account',
          'group' => 'someapp_account',
          'mode' => '0644',
        })

        # check to make sure expected config settings are there
        lines = [
          /<Server\ port="8005"\ shutdown="SHUTDOWN">\n/,
          /\s+<Connector\ port="8080"\ protocol="HTTP\/1.1"\n/,
          /\s+redirectPort="8443" \/>/,
          /\s+<!-- Define an AJP 1.3 Connector on port 8011 -->\n/,
          /\s+<Connector port="8011" protocol="AJP\/1.3" redirectPort="8443" \/>/,
        ]
        lines.each do |l|
          should contain_file(config_file).with_content(l)
        end

        # last, let's ensure our service is ther
        should contain_service('tomcat6-someapp').with({
          'enable' => true,
          'require' => 'File[/etc/init.d/tomcat6-someapp]',
        })
      end

      context "with port overrides" do
        let(:params) { {
          'account' => 'someapp_acct',
          'ajp_port' => '1111',
          'http_port' => '2222',
          'redirect_port' => '3333',
          'shutdown_port' => '4444' }}
        it do
          # check to make sure expected config settings are there
          lines = [
            /<Server\ port="4444"\ shutdown="SHUTDOWN">\n/,
            /\s+<Connector\ port="2222"\ protocol="HTTP\/1.1"\n/,
            /\s+redirectPort="3333" \/>/,
            /\s+<!-- Define an AJP 1.3 Connector on port 1111 -->\n/,
            /\s+<Connector port="1111" protocol="AJP\/1.3" redirectPort="3333" \/>/,
          ]
          config_file = '/home/someapp_acct/tomcat6-someapp/conf/server.xml'
          lines.each do |l|
            should contain_file(config_file).with_content(l)
          end # lines
        end # it do
      end # context - with port overrides
    end

    context "test override of home owner and group" do
      let :title do
        'someapp'
      end
      let :params do
        {
          'account' => 'someapp_acct',
          'home_owner' => 'content_acct',
          'home_group' => 'content_group',
        }
      end
      home_dirs = [
        '/home/someapp_acct/tomcat6-someapp',
        '/home/someapp_acct/tomcat6-someapp/conf/Catalina',
        '/home/someapp_acct/tomcat6-someapp/lib',
        '/home/someapp_acct/tomcat6-someapp/webapps',
        '/var/cache/tomcat6-someapp',
        '/var/cache/tomcat6-someapp/work',
        '/var/cache/tomcat6-someapp/temp',
      ]
      it do
        home_dirs.each do |d|
          should contain_file(d).with({
            'ensure' => 'directory',
            'owner' => 'content_acct',
            'group' => 'content_group',
          })
        end
      end
    end
  end
end
