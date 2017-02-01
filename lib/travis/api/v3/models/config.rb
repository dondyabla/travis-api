module Travis::API::V3
  class Models::Config
    attr_reader :job

    def initialize(job)
      @job = job
    end

    def config
      config = @job.config
      config = obfuscate_config(config)
    end

    def obfuscate_config(config)
      config.delete(:gemfile) if config[:gemfile]
      config.delete(:linux_shared) if config[:linux_shared]
      config.delete(:notifications) if config[:notifications]
      config
    end
  end
end
