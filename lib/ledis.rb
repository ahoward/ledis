# -*- encoding : utf-8 -*-
#
# NAME
#
#   ledis
#
#  
# SYNOPSIS
#
#   a K.I.S.S auto-rotating redis logger for ruby/rails
#
#   Ruby
#  
#     redis = Redis.new
#    
#     logger = Ledis.logger redis
#  
#     logger = Ledis.new
#  
#     logger = Ledis.new do |config|
#
#       config.redis = Redis.new
#
#       config.list = 'teh_foo:log'
#
#       config.cap = 2 ** 16
#
#     end
#  
#   Rails
#  
#     ### file: config/environments/development.rb
#  
#     config.logger = Ledis.logger do |logger|
#  
#       logger.list = "teh_rails_app:#{ Rails.env }:log"
#  
#     end
#  
#  
# DESCRIPTION
#
#   ledis logs yo shiznit to redis.  it's got built in logic to auto-truncate
#   logs when they get to big
#
#     logger.truncate(2 **16)
#
#   and to grab the most recent ones
#
#     puts logger.tail(1024)
#
#   it's list/line oriented, just like a log file and makes no attempt to
#   annotated log lines or add fancy data structures to them
#
# INSTALL
#
#   gem 'ledis'
#

require 'logger'

module Ledis
##
#
  class << Ledis
    def version
      '0.0.1'
    end

    def dependencies
      {
        'map'             => [ 'map'           , ' >= 6.0.1' ],
        'redis'           => [ 'redis'         , ' >= 2.2.2' ]
      }
    end
  end

  begin
    require 'rubygems'
  rescue LoadError
    nil
  end

  dependencies.each do |lib, dependency|
    gem(*dependency) if defined?(gem)
    require(lib)
  end

##
#
  class << Ledis
    def logger(*args, &block)
      return rails_logger(*args, &block) if defined?(::Rails.application)

      Logger.new(*args, &block)
    end

    def rails_logger(*args, &block)
      config = ::Rails.application.config

      logger = Logger.new(*args, &block)

      if defined?(::ActiveSupport::TaggedLogging)
        logger = ::ActiveSupport::TaggedLogging.new(logger)
      end

      logger.level = config.log_level

      logger
    end
  end

##
#
  class Logger < ::Logger
  #
    attr_accessor :logdev
    attr_accessor :formatter

    def initialize(*args, &block)
      super(STDERR)
      @logdev = LogDevice.new(*args, &block)
      @formatter = Formatter.new
    end

    class Formatter < ::Logger::Formatter
      Format  = "%s, [%s#%d] %5s : %s\n"

      def call(severity, time, progname, msg)
        Format %
          [severity[0..0], format_datetime(time), $$, severity, msg2str(msg)]
      end
    end

    def << (*args)
      super
      self
    end

    def level=(level)
      @level = level_for(level)
    end

    Levels =
      Hash[ Severity.constants.map{|c| [c.to_s.downcase, Severity.const_get(c)]} ]

    def level_for(level)
      case level
        when Integer
          Levels[ Levels.invert[level] || 0 ]
        else
          Levels[ level.to_s.downcase || 'debug' ]
      end
    end

    %w(
      redis redis=
      list list=
      cap cap=
      step step=
      cycle cycle=
      tail
      truncate
      size
    ).each do |method|
      case method
        when /=/
          class_eval <<-__, __FILE__, __LINE__
            def #{ method }(arg)
              @logdev.#{ method }(arg)
            end
          __

        else
          class_eval <<-__, __FILE__, __LINE__
            def #{ method }(*args, &block)
              @logdev.#{ method }(*args, &block)
            end
          __
      end
    end

  ##
  #
    class LogDevice
      attr_accessor :config
      attr_accessor :cap
      attr_accessor :step
      attr_accessor :cycle
      attr_accessor :list

      def initialize(*args, &block)
        config = Map.options_for!(args)
        config[:redis] ||= args.shift
        configure(config, &block)
      end

      def configure(config = {}, &block)
        @config = Map.for(config)

        block.call(@config) if block

        @redis = @config[:redis] || @redis
        @cap   = @config[:cap]   || (2 ** 16)
        @step  = @config[:step]  || 0
        @cycle = @config[:cycle] || (2 ** 8)
        @list  = @config[:list]  || 'ledis:log'
      end

      def redis
        @redis ||= Redis.new
      end

      def redis=(redis)
        @redis = redis
      end

      def write(message)
        begin
          redis.lpush(list, message)
        rescue Object => e
          error = "#{ e.message } (#{ e.class })\n#{ Array(e.backtrace).join(10.chr) }"
          STDERR.puts(error)
          STDERR.puts(message)
        end
      ensure
        if (@step % @cycle).zero?
          truncate(@cap) rescue nil
        end
        @step = (@step + 1) % @cycle
      end

      if defined?(Rails::Server) and STDOUT.tty? and not defined?(ActiveSupport::Logger.broadcast)
        alias_method('__write__', 'write')

        def write(message, &block)
          STDOUT.puts(message)
          __write__(message, &block)
        end
      end

      def close
        redis.quit rescue nil
      end

      def tail(n = 1024)
        redis.lrange(list, 0, n - 1).reverse
      end

      def truncate(size)
        redis.ltrim(list, 0, size - 1)
      end

      def size
        redis.llen(list)
      end
    end
  end
end
