describe Travis::API::V3::Services::Config::Find, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:owner)       { owner_type.find(repo.owner_id)}
  let(:build)       { repo.builds.last }
  let(:default_branch) { repo.default_branch}
  let(:def_branch_jobs){ Travis::API::V3::Models::Build.find(default_branch.last_build.id).jobs}
  let(:jobs)        { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:job)         { Travis::API::V3::Models::Build.find(build.id).jobs.last }
  let(:config)      { job.config }
  let(:parsed_body) { JSON.load(body) }

  describe 'obfuscated config' do
    describe 'leaves regualr vars untouched' do
      before do
        job.update_attributes(config: config.merge!(rvm: '1.8.7', env: 'FOO=foo'))
        get("/v3/job/#{job.id}/config")
      end

      example    { expect(last_response).to be_ok }
      example    { expect(parsed_body).to be == { "@type"=>"config",
                                                  "rvm"=>"1.8.7",
                                                  "language"=>"ruby",
                                                  "group"=>"stable",
                                                  "dist"=>"precise",
                                                  "os"=>"linux",
                                                  "env"=>"FOO=foo"
                                                }}
    end

    describe 'obfuscates env vars, including accidents' do
      before do
        p repo.key.secure
        # secure = job.repository.key.secure
        job.update_attributes(config: config.merge!(rvm: '1.8.7', env: [secure.encrypt('BAR=barbaz'), secure.encrypt('PROBLEM'),'FOO=foo']))
        get("/v3/job/#{job.id}/config")
      end

      example    { expect(last_response).to be_ok }
      example    { expect(parsed_body).to be == { "@type"=>"config",
                                                  "rvm"=>"1.8.7",
                                                  "language"=>"ruby",
                                                  "group"=>"stable",
                                                  "dist"=>"precise",
                                                  "os"=>"linux",
                                                  "env"=>"FOO=foo"
                                                }}
      # secure = job.repository.key.secure
      # job.expects(:secure_env_enabled?).at_least_once.returns(true)
      # config = { rvm: '1.8.7',
      #            env: [secure.encrypt('BAR=barbaz'), secure.encrypt('PROBLEM'), 'FOO=foo']
      #          }
      # job.config = config
      #
      # job.obfuscated_config.should == {
      #   rvm: '1.8.7',
      #   env: 'BAR=[secure] [secure] FOO=foo'
      # }
    end

    describe 'normalizes env vars which are hashes to strings' do
      # job.expects(:secure_env_enabled?).at_least_once.returns(true)
      #
      # config = { rvm: '1.8.7',
      #            env: [{FOO: 'bar', BAR: 'baz'},
      #                     job.repository.key.secure.encrypt('BAR=barbaz')]
      #          }
      # job.config = config
      #
      # job.obfuscated_config.should == {
      #   rvm: '1.8.7',
      #   env: 'FOO=bar BAR=baz BAR=[secure]'
      # }
    end

    describe 'removes addons config if it is not a hash' do
      before do
        job.update_attributes(config: job.config.merge!(rvm: '1.8.7', addons: 'foo'))
        get("/v3/job/#{job.id}/config")
      end

      example    { expect(last_response).to be_ok }
      example    { expect(parsed_body).to be == { "@type"=>"config",
                                                  "rvm"=>"1.8.7",
                                                  "language"=>"ruby",
                                                  "group"=>"stable",
                                                  "dist"=>"precise",
                                                  "os"=>"linux"
                                                }}
    end

    describe 'removes addons items which are not safelisted' do
      before do
        job.update_attributes(config: job.config.merge!(rvm: '1.8.7', addons: { sauce_connect: true, firefox: '22.0' }))
        get("/v3/job/#{job.id}/config")
      end

      example    { expect(last_response).to be_ok }
      example    { expect(parsed_body).to be == { "@type"=>"config",
                                                  "rvm"=>"1.8.7",
                                                  "language"=>"ruby",
                                                  "group"=>"stable",
                                                  "dist"=>"precise",
                                                  "os"=>"linux",
                                                  "addons"=>{"firefox"=>"22.0"}
                                                }}
    end

    describe 'removes source key, gemfile, notifications, linux_shared' do
      before do
        job.update_attributes(config: job.config.merge!(gemfile: 'ddddd', rvm: '1.8.7', source_key: '1234', linux_shared: 'precise', notifications: 'email'))
        get("/v3/job/#{job.id}/config")
      end

      example    { expect(last_response).to be_ok }
      example    { expect(parsed_body).to be == { "@type"=>"config",
                                                  "rvm"=>"1.8.7",
                                                  "language"=>"ruby",
                                                  "group"=>"stable",
                                                  "dist"=>"precise",
                                                  "os"=>"linux"
                                                }}
    end


    context 'when job has secure env disabled' do
      # let :job do
      #   job = Travis::API::V3::Models::Job.new(repository: repo)
      #   job.expects(:secure_env_enabled?).returns(false).at_least_once
      #   job
      # end
      #
      # it 'removes secure env vars' do
      #   config = { rvm: '1.8.7',
      #              env: [job.repository.key.secure.encrypt('BAR=barbaz'), 'FOO=foo']
      #            }
      #   job.config = config
      #
      #   job.obfuscated_config.should == {
      #     rvm: '1.8.7',
      #     env: 'FOO=foo'
      #   }
      end

      it 'works even if it removes all env vars' do
        # config = { rvm: '1.8.7',
        #            env: [job.repository.key.secure.encrypt('BAR=barbaz')]
        #          }
        # job.config = config
        #
        # job.obfuscated_config.should == {
        #   rvm: '1.8.7',
        #   env: nil
        # }
      end

      it 'normalizes env vars which are hashes to strings' do
      #   config = { rvm: '1.8.7',
      #              env: [{FOO: 'bar', BAR: 'baz'},
      #                       job.repository.key.secure.encrypt('BAR=barbaz')]
      #            }
      #   job.config = config
      #
      #   job.obfuscated_config.should == {
      #     rvm: '1.8.7',
      #     env: 'FOO=bar BAR=baz'
      #   }
      # end
    end
  end

  # describe 'decrypted config' do
  #   # before { repo.regenerate_key! }
  #
  #   it 'handles nil env' do
  #     job = Job.new(repository: repo)
  #     job.config = { rvm: '1.8.7', env: nil, global_env: nil }
  #
  #     job.decrypted_config.should == {
  #       rvm: '1.8.7',
  #       env: nil,
  #       global_env: nil
  #     }
  #   end

    # it 'normalizes env vars which are hashes to strings' do
    #   job = Job.new(repository: repo)
    #   job.expects(:secure_env_enabled?).at_least_once.returns(true)
    #
    #   config = { rvm: '1.8.7',
    #              env: [{FOO: 'bar', BAR: 'baz'},
    #                       job.repository.key.secure.encrypt('BAR=barbaz')],
    #              global_env: [{FOO: 'foo', BAR: 'bar'},
    #                       job.repository.key.secure.encrypt('BAZ=baz')]
    #            }
    #   job.config = config
    #
    #   job.decrypted_config.should == {
    #     rvm: '1.8.7',
    #     env: ["FOO=bar BAR=baz", "SECURE BAR=barbaz"],
    #     global_env: ["FOO=foo BAR=bar", "SECURE BAZ=baz"]
    #   }
    # end
    #
    # it 'does not change original config' do
    #   job = Job.new(repository: repo)
    #   job.expects(:secure_env_enabled?).at_least_once.returns(true)
    #
    #   config = {
    #              env: [{secure: 'invalid'}],
    #              global_env: [{secure: 'invalid'}]
    #            }
    #   job.config = config
    #
    #   job.decrypted_config
    #   job.config.should == {
    #     env: [{ secure: 'invalid' }],
    #     global_env: [{ secure: 'invalid' }]
    #   }
    # end
    #
    # it 'leaves regular vars untouched' do
    #   job = Job.new(repository: repo)
    #   job.expects(:secure_env_enabled?).returns(true).at_least_once
    #   job.config = { rvm: '1.8.7', env: 'FOO=foo', global_env: 'BAR=bar' }
    #
    #   job.decrypted_config.should == {
    #     rvm: '1.8.7',
    #     env: ['FOO=foo'],
    #     global_env: ['BAR=bar']
    #   }
    # end
    #
    # context 'when secure env is not enabled' do
    #   let :job do
    #     job = Job.new(repository: repo)
    #     job.expects(:secure_env_enabled?).returns(false).at_least_once
    #     job
    #   end
    #
    #   it 'removes secure env vars' do
    #     config = { rvm: '1.8.7',
    #                env: [job.repository.key.secure.encrypt('BAR=barbaz'), 'FOO=foo'],
    #                global_env: [job.repository.key.secure.encrypt('BAR=barbaz'), 'BAR=bar']
    #              }
    #     job.config = config
    #
    #     job.decrypted_config.should == {
    #       rvm: '1.8.7',
    #       env: ['FOO=foo'],
    #       global_env: ['BAR=bar']
    #     }
    #   end
    #
    #   it 'removes only secured env vars' do
    #     config = { rvm: '1.8.7',
    #                env: [job.repository.key.secure.encrypt('BAR=barbaz'), 'FOO=foo']
    #              }
    #     job.config = config
    #
    #     job.decrypted_config.should == {
    #       rvm: '1.8.7',
    #       env: ['FOO=foo']
    #     }
    #   end
    # end
    #
    # context 'when addons are disabled' do
    #   let :job do
    #     job = Job.new(repository: repo)
    #     job.expects(:addons_enabled?).returns(false).at_least_once
    #     job
    #   end
    #
    #   it 'removes addons if it is not a hash' do
    #     config = { rvm: '1.8.7',
    #                addons: []
    #              }
    #     job.config = config
    #
    #     job.decrypted_config.should == {
    #       rvm: '1.8.7'
    #     }
    #   end
    #
    #   it 'removes addons items which are not safelisted' do
    #     config = { rvm: '1.8.7',
    #                addons: {
    #                  sauce_connect: {
    #                    username: 'johndoe',
    #                    access_key: job.repository.key.secure.encrypt('foobar')
    #                  },
    #                  firefox: '22.0',
    #                  mariadb: '10.1',
    #                  postgresql: '9.3',
    #                  hosts: %w(travis.dev),
    #                  apt_packages: %w(curl git),
    #                  apt_sources: %w(deadsnakes)
    #                }
    #              }
    #     job.config = config
    #
    #     job.decrypted_config.should == {
    #       rvm: '1.8.7',
    #       addons: {
    #         firefox: '22.0',
    #         mariadb: '10.1',
    #         postgresql: '9.3',
    #         hosts: %w(travis.dev),
    #         apt_packages: %w(curl git),
    #         apt_sources: %w(deadsnakes)
    #       }
    #     }
    #   end
    # end

  #   context 'when job has secure env enabled' do
  #     let :job do
  #       job = Job.new(repository: repo)
  #       job.expects(:secure_env_enabled?).returns(true).at_least_once
  #       job
  #     end
  #
  #     it 'decrypts env vars' do
  #       config = { rvm: '1.8.7',
  #                  env: job.repository.key.secure.encrypt('BAR=barbaz'),
  #                  global_env: job.repository.key.secure.encrypt('BAR=bazbar')
  #                }
  #       job.config = config
  #
  #       job.decrypted_config.should == {
  #         rvm: '1.8.7',
  #         env: ['SECURE BAR=barbaz'],
  #         global_env: ['SECURE BAR=bazbar']
  #       }
  #     end
  #
  #     it 'decrypts only secure env vars' do
  #       config = { rvm: '1.8.7',
  #                  env: [job.repository.key.secure.encrypt('BAR=bar'), 'FOO=foo'],
  #                  global_env: [job.repository.key.secure.encrypt('BAZ=baz'), 'QUX=qux']
  #                }
  #       job.config = config
  #
  #       job.decrypted_config.should == {
  #         rvm: '1.8.7',
  #         env: ['SECURE BAR=bar', 'FOO=foo'],
  #         global_env: ['SECURE BAZ=baz', 'QUX=qux']
  #       }
  #     end
  #   end
  #
  #   context 'when job has addons enabled' do
  #     let :job do
  #       job = Job.new(repository: repo)
  #       job.expects(:addons_enabled?).returns(true).at_least_once
  #       job
  #     end
  #
  #     it 'decrypts addons config' do
  #       config = { rvm: '1.8.7',
  #                  addons: {
  #                    sauce_connect: {
  #                      username: 'johndoe',
  #                      access_key: job.repository.key.secure.encrypt('foobar')
  #                    }
  #                  }
  #                }
  #       job.config = config
  #
  #       job.decrypted_config.should == {
  #         rvm: '1.8.7',
  #         addons: {
  #           sauce_connect: {
  #             username: 'johndoe',
  #             access_key: 'foobar'
  #           }
  #         }
  #       }
  #     end
  #
  #     it 'decrypts deploy addon config' do
  #       config = { rvm: '1.8.7',
  #                  deploy: { foo: job.repository.key.secure.encrypt('foobar') }
  #                }
  #       job.config = config
  #
  #       job.decrypted_config.should == {
  #         rvm: '1.8.7',
  #         addons: {
  #           deploy: { foo: 'foobar' }
  #         }
  #       }
  #     end
  #
  #     it 'removes addons config if it is an array and deploy is present' do
  #       config = { rvm: '1.8.7',
  #                  addons: ["foo"],
  #                  deploy: { foo: 'bar'}
  #                }
  #       job.config = config
  #
  #       job.decrypted_config.should == {
  #         rvm: '1.8.7',
  #         addons: {
  #           deploy: { foo: 'bar' }
  #         }
  #       }
  #     end
  #   end
  # end
end
