module Travis::API::V3
  class Models::Config
    attr_reader :job

    SAFELISTED_ADDONS = %w(
      apt
      apt_packages
      apt_sources
      firefox
      hosts
      mariadb
      postgresql
      ssh_known_hosts
    ).freeze

    def initialize(job)
      @job = job
    end

    def config
      config = @job.config
      config = normalize_config(config)
      # config = obfuscate_config(config)
    end

    def normalize_config(config)
      config.delete(:gemfile) if config[:gemfile]
      config.delete(:linux_shared) if config[:linux_shared]
      config.delete(:notifications) if config[:notifications]
      config.delete(:source_key) if config[:source_key]
      delete_addons(config)
      config
    end

    def delete_addons(config)
      if config[:addons].is_a?(Hash)
        config[:addons].keep_if { |key, _| SAFELISTED_ADDONS.include? key.to_s }
      else
        config.delete(:addons)
      end
    end

  end
end
