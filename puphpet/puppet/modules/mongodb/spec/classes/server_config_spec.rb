require 'spec_helper'

describe 'mongodb::server::config', type: :class do
  with_debian_facts

  describe 'with preset variables' do
    let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js' }" }

    it {
      is_expected.to contain_file('/etc/mongod.conf')
    }
  end

  describe 'with default values' do
    let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', create_admin => false, rcfile => '/root/.mongorc.js', store_creds => true, ensure => present, user => 'mongod', group => 'mongod', port => 29017, bind_ip => ['0.0.0.0'], fork => true, logpath => '/var/log/mongo/mongod.log', logappend => true }" }

    it {
      is_expected.to contain_file('/etc/mongod.conf').with(mode: '0644',
                                                           owner: 'root',
                                                           group: 'root')

      is_expected.to contain_file('/etc/mongod.conf').with_content(%r{^dbpath=\/var\/lib\/mongo})
      is_expected.to contain_file('/etc/mongod.conf').with_content(%r{bind_ip\s=\s0\.0\.0\.0})
      is_expected.to contain_file('/etc/mongod.conf').with_content(%r{^port = 29017$})
      is_expected.to contain_file('/etc/mongod.conf').with_content(%r{^logappend=true})
      is_expected.to contain_file('/etc/mongod.conf').with_content(%r{^logpath=\/var\/log\/mongo\/mongod\.log})
      is_expected.to contain_file('/etc/mongod.conf').with_content(%r{^fork=true})

      is_expected.to contain_file('/root/.mongorc.js').with(ensure: 'absent')
      is_expected.not_to contain_exec('fix dbpath permissions')
    }
  end

  describe 'with absent ensure' do
    let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', ensure => absent }" }

    it {
      is_expected.to contain_file('/etc/mongod.conf').with(ensure: 'absent')
    }
  end

  describe 'with specific bind_ip values and ipv6' do
    let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', ensure => present, bind_ip => ['127.0.0.1', 'fd00:beef:dead:55::143'], ipv6 => true }" }

    it {
      is_expected.to contain_file('/etc/mongod.conf').with_content(%r{bind_ip\s=\s127\.0\.0\.1\,fd00:beef:dead:55::143})
      is_expected.to contain_file('/etc/mongod.conf').with_content(%r{ipv6=true})
    }
  end

  describe 'with specific bind_ip values' do
    let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', ensure => present, bind_ip => ['127.0.0.1', '10.1.1.13']}" }

    it {
      is_expected.to contain_file('/etc/mongod.conf').with_content(%r{bind_ip\s=\s127\.0\.0\.1\,10\.1\.1\.13})
    }
  end

  describe 'when specifying auth to true' do
    let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', auth => true, dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', ensure => present }" }

    it {
      is_expected.to contain_file('/etc/mongod.conf').with_content(%r{^auth=true})
      is_expected.to contain_file('/root/.mongorc.js')
    }
  end

  describe 'when specifying set_parameter value' do
    let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', set_parameter => 'textSearchEnable=true', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', ensure => present }" }

    it {
      is_expected.to contain_file('/etc/mongod.conf').with_content(%r{^setParameter = textSearchEnable=true})
    }
  end

  describe 'with journal:' do
    context 'on true with i686 architecture' do
      let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', ensure => present, journal => true }" }
      let(:facts) { super().merge(architecture: 'i686') }

      it {
        is_expected.to contain_file('/etc/mongod.conf').with_content(%r{^journal = true})
      }
    end
  end

  # check nested quota and quotafiles
  describe 'with quota to' do
    context 'true and without quotafiles' do
      let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', ensure => present, quota => true }" }

      it {
        is_expected.to contain_file('/etc/mongod.conf').with_content(%r{^quota = true})
      }
    end

    context 'true and with quotafiles' do
      let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', ensure => present, quota => true, quotafiles => 1 }" }

      it {
        is_expected.to contain_file('/etc/mongod.conf').with_content(%r{quota = true})
        is_expected.to contain_file('/etc/mongod.conf').with_content(%r{quotaFiles = 1})
      }
    end
  end

  describe 'when specifying syslog value' do
    context 'it should be set to true' do
      let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', ensure => present, syslog => true, logpath => false }" }

      it {
        is_expected.to contain_file('/etc/mongod.conf').with_content(%r{^syslog = true})
      }
    end

    context 'if logpath is also set an error should be raised' do
      let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', ensure => present, syslog => true, logpath => '/var/log/mongo/mongod.log' }" }

      it {
        expect { is_expected.to contain_file('/etc/mongod.conf') }.to raise_error(Puppet::Error, %r{You cannot use syslog with logpath})
      }
    end
  end

  describe 'with store_creds' do
    context 'true' do
      let(:pre_condition) { "class { 'mongodb::server': admin_username => 'admin', admin_password => 'password', auth => true, store_creds => true, config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', ensure => present }" }

      it {
        is_expected.to contain_file('/root/.mongorc.js').
          with_ensure('present').
          with_owner('root').
          with_group('root').
          with_mode('0600').
          with_content(%r{db.auth\('admin', 'password'\)})
      }
    end

    context 'false' do
      let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', ensure => present, store_creds => false  }" }

      it {
        is_expected.to contain_file('/root/.mongorc.js').with_ensure('absent')
      }
    end
  end

  describe 'with custom pidfilemode' do
    let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', pidfilepath => '/var/run/mongodb/mongod.pid', pidfilemode => '0640' }" }

    it { is_expected.to contain_file('/var/run/mongodb/mongod.pid').with_mode('0640') }
  end

  describe 'with dbpath_fix enabled' do
    let(:pre_condition) { "class { 'mongodb::server': config => '/etc/mongod.conf', dbpath => '/var/lib/mongo', rcfile => '/root/.mongorc.js', dbpath_fix => true, user => 'foo', group => 'bar' }" }

    it {
      is_expected.to contain_exec('fix dbpath permissions').with(
        command: 'chown -R foo:bar /var/lib/mongo',
        path: ['/usr/bin', '/bin'],
        onlyif: "find /var/lib/mongo -not -user foo -o -not -group bar -print -quit | grep -q '.*'"
      )
      is_expected.to contain_exec('fix dbpath permissions').that_subscribes_to('File[/var/lib/mongo]')
    }
  end
end
