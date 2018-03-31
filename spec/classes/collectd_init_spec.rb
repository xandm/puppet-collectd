require 'spec_helper'

describe 'collectd', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os} " do
      let :facts do
        facts
      end

      options = os_specific_options(facts)
      context 'with all defaults' do
        it { is_expected.to contain_class('collectd') }
        it { is_expected.to contain_class('collectd::params') }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_anchor('collectd::begin') }
        it { is_expected.to contain_anchor('collectd::end') }
        it { is_expected.to contain_file('collectd.conf').without_content }
        it { is_expected.to contain_file('collectd.d').with_ensure('directory') }
        it { is_expected.to contain_file_line('include_conf_d').with_ensure('absent') }
        it { is_expected.to contain_file_line('include_conf_d_dot_conf').with_ensure('present') }
        it { is_expected.to contain_package(options[:package]).with_ensure('present') }
        it { is_expected.to contain_package(options[:package]).with_install_options(nil) }
        it { is_expected.to contain_class('collectd::install').that_comes_before('Class[collectd::config]') }
        it { is_expected.to contain_class('collectd::config').that_notifies('Class[collectd::service]') }
        it { is_expected.to contain_class('collectd::service') }
        it do
          is_expected.to contain_service('collectd').with(
            ensure: 'running',
            name: options[:service]
          )
        end
        if facts[:osfamily] == 'RedHat'
          it { is_expected.to contain_class('epel') }
        end
      end

      context 'with collectd::install::package_install_options' do
        context 'set to a valid array' do
          let :params do
            { package_install_options: ['--nogpgcheck'] }
          end

          it { is_expected.to contain_package(options[:package]).with_install_options(['--nogpgcheck']) }
        end
      end

      context 'when purge_config is enabled' do
        let(:params) { { purge_config: true } }

        it { is_expected.to contain_file('collectd.conf').with_content(%r{FQDNLookup true}) }
        it { is_expected.to contain_file('collectd.conf').with_content(%r{Interval}) }
        it { is_expected.to contain_file('collectd.conf').with_content(%r{Timeout}) }
        it { is_expected.to contain_file('collectd.conf').with_content(%r{ReadThreads}) }
        it { is_expected.to contain_file('collectd.conf').with_content(%r{WriteThreads}) }
        it { is_expected.to contain_file('collectd.conf').without_content(%r{^WriteQueueLimitLow}) }
        it { is_expected.to contain_file('collectd.conf').without_content(%r{^WriteQueueLimitHigh}) }
        it { is_expected.to contain_file('collectd.conf').without_content(%r{^CollectInternalStats}) }
        it { is_expected.not_to contain_file_line('include_conf_d') }
        it { is_expected.to contain_file('collectd.conf').with_content(%r{^# Generated by Puppet$}) }

        context 'with fqdnlookup => false' do
          let(:params) do
            {
              purge_config: true,
              fqdnlookup: false
            }
          end

          it { is_expected.to contain_file('collectd.conf').with_content(%r{^FQDNLookup false}) }
        end

        context 'with typesdb => ["/path/to/types.db"]' do
          let(:params) do
            {
              purge_config: true,
              typesdb: ['/path/to/types.db']
            }
          end

          it { is_expected.to contain_file('collectd.conf').with_content(%r{^TypesDB "/path/to/types.db"}) }
        end

        context 'with write_queue_limit_low => 100' do
          let(:params) do
            {
              purge_config: true,
              write_queue_limit_low: '100'
            }
          end

          it { is_expected.to contain_file('collectd.conf').with_content(%r{^WriteQueueLimitLow 100}) }
        end

        context 'with write_queue_limit_high => 100' do
          let(:params) do
            {
              purge_config: true,
              write_queue_limit_high: '100'
            }
          end

          it { is_expected.to contain_file('collectd.conf').with_content(%r{^WriteQueueLimitHigh 100}) }
        end

        context 'with include => ["/some/include/path"]' do
          let(:params) do
            {
              purge_config: true,
              include: ['/some/include/path']
            }
          end

          it { is_expected.to contain_file('collectd.conf').with_content(%r{^Include "/some/include/path"}) }
        end

        context 'with has_wordexp => false' do
          let(:params) do
            {
              purge_config: true,
              has_wordexp: false
            }
          end

          it { is_expected.to contain_file('collectd.conf').with_content(%r{^Include "#{options[:plugin_conf_dir]}/"}) }
          it { is_expected.to contain_file('collectd.conf').without_content(%r{^Include "#{options[:plugin_conf_dir]}/\*.conf"}) }
        end

        context 'with has_wordexp => true' do
          let(:params) do
            {
              purge_config: true,
              has_wordexp: true
            }
          end

          it { is_expected.to contain_file('collectd.conf').with_content(%r{^Include "#{options[:plugin_conf_dir]}/\*.conf"}) }
          it { is_expected.to contain_file('collectd.conf').without_content(%r{^Include "#{options[:plugin_conf_dir]}/"}) }
        end

        context 'with internal_stats => true' do
          context 'with collectd_version = 5.5' do
            let(:facts) do
              super().merge(collectd_version: '5.5')
            end
            let(:params) do
              {
                purge_config: true,
                internal_stats: true
              }
            end

            it { is_expected.to contain_file('collectd.conf').without_content(%r{^CollectInternalStats}) }
          end

          context 'with collectd_version = 5.6' do
            let(:facts) do
              super().merge(collectd_version: '5.6')
            end
            let(:params) do
              {
                purge_config: true,
                internal_stats: true
              }
            end

            it { is_expected.to contain_file('collectd.conf').with_content(%r{^CollectInternalStats true}) }
          end
        end
        context 'when custom package_name is set' do
          let(:params) { { package_name: 'collectd-core' } }

          it { is_expected.to contain_package('collectd-core').with_ensure('present') }
        end
        context 'when manage_package is false' do
          let(:params) { { manage_package: false } }

          it { is_expected.not_to contain_package(options[:package]) }
        end

        context 'when manage_package is true' do
          let(:params) { { manage_package: true } }

          it { is_expected.to contain_package(options[:package]).with_ensure('present') }
        end

        context 'when manage_repo is false' do
          let(:params) { { manage_repo: false } }

          it { is_expected.not_to contain_apt__source('ppa_collectd') }
        end

        context 'when manage_repo is true' do
          context 'and ci_package_repo empty' do
            let(:params) { { manage_repo: true } }

            if facts[:osfamily] == 'RedHat'
              it { is_expected.to contain_class('epel') }
            end
          end

          context 'and ci_package_repo set to a version' do
            context 'and package_keyserver is default' do
              let(:params) do
                {
                  manage_repo: true,
                  ci_package_repo: '5.6'
                }
              end

              if facts[:osfamily] == 'RedHat'
                it { is_expected.to contain_yumrepo('collectd-ci').with_gpgkey('https://pkg.ci.collectd.org/pubkey.asc').with_baseurl("https://pkg.ci.collectd.org/rpm/collectd-5.6/epel-#{facts[:operatingsystemmajrelease]}-x86_64") }
              end
              if facts[:osfamily] == 'Debian'
                it do
                  is_expected.to contain_apt__source('collectd-ci').
                    with_location('https://pkg.ci.collectd.org/deb/').
                    with_key(
                      'id'     => 'F806817DC3F5EA417F9FA2963994D24FB8543576',
                      'server' => 'keyserver.ubuntu.com'
                    ).
                    with_repos('collectd-5.6')
                end
              end
            end
            context 'and package_keyserver is set' do
              let(:params) do
                {
                  manage_repo: true,
                  ci_package_repo: '5.6',
                  package_keyserver: 'pgp.mit.edu'
                }
              end

              if facts[:osfamily] == 'RedHat'
                it { is_expected.to contain_yumrepo('collectd-ci').with_gpgkey('https://pkg.ci.collectd.org/pubkey.asc').with_baseurl("https://pkg.ci.collectd.org/rpm/collectd-5.6/epel-#{facts[:operatingsystemmajrelease]}-x86_64") }
              end
              if facts[:osfamily] == 'Debian'
                it do
                  is_expected.to contain_apt__source('collectd-ci').
                    with_location('https://pkg.ci.collectd.org/deb/').
                    with_key(
                      'id'     => 'F806817DC3F5EA417F9FA2963994D24FB8543576',
                      'server' => 'pgp.mit.edu'
                    ).
                    with_repos('collectd-5.6')
                end
              end
            end
          end
        end

        context 'when manage_service is true' do
          let(:params) { { manage_service: true } }

          it { is_expected.to contain_service('collectd').with_ensure('running') }
        end

        context 'when manage_service is false' do
          let(:params) { { manage_service: false } }

          it { is_expected.not_to contain_service('collectd') }
        end

        context 'when manage_service is undefined' do
          let(:params) { { manage_service: nil } }

          it { is_expected.to contain_service('collectd').with_ensure('running') }
        end

        context 'when plugin_conf_dir_mode is set' do
          let(:params) { { plugin_conf_dir_mode: '0755' } }

          it { is_expected.to contain_file('collectd.d').with_mode('0755') }
        end

        context 'when conf_content is set' do
          let(:params) { { conf_content: 'Hello World' } }

          it { is_expected.to contain_file('collectd.conf').with_content(%r{Hello World}) }
        end
        context 'on non supported operating systems' do
          let(:facts) { { os: { family: 'foo' } } }

          it 'fails' do
            is_expected.to compile.and_raise_error(%r{foo is not supported})
          end
        end
      end
    end
  end
end
