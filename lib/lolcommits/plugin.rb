# -*- encoding : utf-8 -*-
module Lolcommits
  class Plugin
    include Methadone::CLILogging

    attr_accessor :runner, :options

    def initialize(runner)
      debug 'Initializing'
      self.runner = runner
      self.options = ['enabled']
    end

    def execute
      if enabled?
        debug 'I am enabled, about to run'
        run
      else
        debug 'Disabled, doing nothing for execution'
      end
    end

    def run
      debug 'base plugin, does nothing to anything'
    end

    def configuration
      config = runner.config.read_configuration if runner
      return {} unless config
      config[self.class.name] || {}
    end

    # ask for plugin options
    def configure_options!
      puts "Configuring plugin: #{self.class.name}\n"
      options.reduce(Hash.new) do |acc, option|
        print "#{option}: "
        val = STDIN.gets.strip.downcase
        if %w(true yes).include?(val)
          val = true
        elsif %(false no).include?(val)
          val = false
        end
        acc.merge(option => val)
      end
    end

    def enabled?
      configuration['enabled'] == true
    end

    # check config is valid
    def valid_configuration?
      if configured?
        true
      else
        puts "Missing #{self.class.name} config - configure with: lolcommits --config -p #{self.class.name}"
        false
      end
    end

    # empty plugin configuration
    def configured?
      !configuration.empty?
    end

    # uniform puts for plugins
    # dont puts if the runner wants to be silent (stealth mode)
    def puts(*args)
      return if runner && runner.capture_stealth
      super(args)
    end

    # uniform debug logging for plugins
    def debug(msg)
      super("Plugin: #{self.class.to_s}: " + msg)
    end

    # identifying plugin name (for config, listing)
    def self.name
      'plugin'
    end
  end
end
