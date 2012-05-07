module Aspector
  class Logger
    # Log levels
    ERROR = 50
    WARN  = 40
    INFO  = 30
    DEBUG = 20
    TRACE = 10

    DEFAULT_VISIBLE_LEVEL = INFO

    # Actions
    DEFINE_ADVICE          = ["define-advice"  , INFO]
    APPLY                  = ["apply"          , INFO]
    APPLY_TO_METHOD        = ["apply-to-method", DEBUG]
    ENABLE_ASPECT          = ["enable-aspect"  , INFO]
    DISABLE_ASPECT         = ["disable-aspect" , INFO]
    GENERATE_CODE          = ["generate-code"  , DEBUG]

    ENTER_GENERATED_METHOD = ["enter-generated-method", TRACE]
    EXIT_GENERATED_METHOD  = ["exit--generated-method", TRACE]
    EXIT_BECAUSE_DISABLED  = ["exit--because-disabled", TRACE]
    BEFORE_INVOKE_ADVICE   = ["before-invoke-advice"  , TRACE]
    AFTER_INVOKE_ADVICE    = ["after--invoke-advice"  , TRACE]
    BEFORE_WRAPPED_METHOD  = ["before-wrapped-method" , TRACE]
    AFTER_WRAPPED_METHOD   = ["after--wrapped-method" , TRACE]
    BEFORE_INVOKE_PROXY    = ["before-invoke-proxy"   , TRACE]
    AFTER_INVOKE_PROXY     = ["after--invoke-proxy"   , TRACE]

    attr_reader :context
    attr_writer :level

    def initialize context, level = nil
      @context = context
      @level = level
    end

    def level
      return @level if @level

      if (level_string = ENV['ASPECTOR_LOG_LEVEL'])
        @level = string_to_level(level_string)
      else
        @level = DEFAULT_VISIBLE_LEVEL
      end
    end

    def log action_level, *args
      action, level = *action_level

      return if self.level > level

      puts log_prefix(level) << action << " | " << args.join(" | ")
    end

    def log_method_call method, action_level, *args
      action, level = *action_level

      return if self.level > level

      puts log_prefix(level) << method << " | " << action << " | " << args.join(" | ")
    end

    def visible? level
      self.level <= level
    end

    private

    def log_prefix level
      s = "Aspector | " << level_to_string(level) << " | "
      if context.is_a? Aspector::Base
        s << context.class.to_s << " | " << context.aop_target.to_s << " | "
      else
        s << context.to_s << " | "
      end
    end

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

