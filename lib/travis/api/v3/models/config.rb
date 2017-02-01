module Travis::API::V3
  class Models::Config
    attr_reader :config

    def initialize(config)
      @config = config
    end
  end
end
