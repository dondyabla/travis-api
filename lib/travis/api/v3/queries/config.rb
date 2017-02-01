module Travis::API::V3
  class Queries::Config < Query
    params :id, prefix: :job

    def find
      config = Models::Config.new(Models::Job.find(id).config).config
      config = obfuscate_config(config)
      config
    end

    def obfuscate_config(config)
      config.delete(:gemfile) if config[:gemfile]
      config
    end
  end
end
