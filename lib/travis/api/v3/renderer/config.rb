require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Config
    def self.render(config, **options)
      {
        :@type          => 'config'.freeze
      }.merge(config.config)
    end
  end
end
