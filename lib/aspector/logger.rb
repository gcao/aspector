module Aspector
  class Logger

    attr_reader :context
    attr_accessor :level

    def initialize context
      @context = context

      if (level_string = ENV['ASPECTOR_LOG_LEVEL'])
        @level = string_to_level(level_string)
      else
        @level = Logging::DEFAULT_VISIBLE_LEVEL
      end
    end

    def log level, *args
      return if self.level > level

      puts log_prefix(level) << args.join(" | ")
    end

    def visible? level
      self.level <= level
    end

    private

    def log_prefix level
      s = "#{Time.now} | Aspector | " << level_to_string(level) << " | "
      if context.is_a? Aspector::Base
        s << context.class.to_s << " | " << context.target.to_s << " | "
      else
        s << context.to_s << " | "
      end
    end

    def level_to_string level
      case level
      when Logging::ERROR then "ERROR"
      when Logging::WARN  then "WARN "
      when Logging::INFO  then "INFO "
      when Logging::DEBUG then "DEBUG"
      when Logging::TRACE then "TRACE"
      else level.to_s
      end
    end

    def string_to_level level_string
      return Logging::DEFAULT_VISIBLE_LEVEL if level_string.nil? or level_string.strip == ''

      case level_string.downcase
        when 'error' then Logging::ERROR
        when 'warn'  then Logging::WARN
        when 'info'  then Logging::INFO
        when 'debug' then Logging::DEBUG
        when 'trace' then Logging::TRACE
        when 'none'  then Logging::NONE
      end
    end
  end
end

