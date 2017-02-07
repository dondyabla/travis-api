require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/array/wrap'
require 'travis/secure_config'

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

    ENV_VAR_PATTERN = /(?<=\=)(?:(?<q>['"]).*?[^\\]\k<q>|(.*?)(?= \w+=|$))/

    def initialize(job)
      @job = job
    end

    def config
      config = @job.config
      config = normalize_config(config)
      config = obfuscate_config(config)
      config
    end

    def normalize_config(config)
      config.delete(:linux_shared) if config[:linux_shared]
      config.delete(:notifications) if config[:notifications]
      config.delete(:source_key) if config[:source_key]
      delete_addons(config)
      config
    end

    def obfuscate_config(config)
      config[:env] = obfuscate(config[:env]) if config[:env]
      config
    end

    private

      def delete_addons(config)
        if config[:addons].is_a?(Hash)
          config[:addons].keep_if { |key, _| SAFELISTED_ADDONS.include? key.to_s }
        else
          config.delete(:addons)
        end
      end

      def obfuscate(env)
        Array.wrap(env).map do |value|
          obfuscate_values(value).join(' ')
        end
      end

      def obfuscate_values(values)
        Array.wrap(values).compact.map do |value|
          obfuscate_value(value)
        end
      end

      def obfuscate_value(value)
        secure.decrypt(value) do |decrypted|
          obfuscate_env_vars(decrypted)
        end
      end

      def obfuscate_env_vars(line)
        if line.respond_to?(:gsub)
          line.gsub(ENV_VAR_PATTERN) { |val| '[secure]' }
        else
          '[One of the secure variables in your .travis.yml has an invalid format.]'
        end
      end

      def secure
        @secure ||= Travis::SecureConfig.new(key)
      end

      def key
        @key ||= options[:key_fetcher].call
      end

  end
end
