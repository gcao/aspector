module Aspector
  class Logger
    # Log levels
    ERROR = 50
    WARN  = 40
    INFO  = 30
    DEBUG = 20
    TRACE = 10

    DEFAULT_LEVEL = TRACE

    # Actions
    DEFINE_ADVICE = %W"define-advice"
    APPLY = %W"apply"
    APPLY_TO_METHOD = %W"apply-to-method #{DEBUG}"

    attr_reader :target
    attr_writer :level

    def initialize target
      @target = target
    end

    def level
      return @level if @level

      if (level_string = ENV['ASPECTOR_LOG_LEVEL'])
        @level = string_to_level(level_string)
      else
        @level = DEFAULT_LEVEL
      end
    end

    def log action_level, *args
      action = action_level[0]
      level = (action_level[1] || '30').to_i
      return if self.level > level
      puts "Aspector | #{level_to_string(level)} | #{target} | #{action} | #{args.join(' | ')}"
    end

    private

    def level_to_string level
      case level
      when ERROR then "ERROR"
      when WARN  then "WARN "
      when INFO  then "INFO "
      when DEBUG then "DEBUG"
      when TRACE then "TRACE"
      else level.to_s
      end
    end

    def string_to_level level_string
      return if level_string.nil? or level_string.strip == ''

      case level_string.downcase
      when 'error' then ERROR
      when 'warn'  then WARN
      when 'info'  then INFO
      when 'debug' then DEBUG
      when 'trace' then TRACE
      end
    end
  end
end

