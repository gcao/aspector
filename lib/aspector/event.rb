module Aspector
  class Event
    # Priorities
    ERROR = 50
    WARN  = 40
    INFO  = 30
    DEBUG = 20
    TRACE = 10

    # name and priority
    DEFINE_ADVICE          = ["define-advice", INFO]
    APPLY                  = ["apply", INFO]
    APPLY_TO_METHOD        = ["apply-to-method", DEBUG]
    ENABLE_ASPECT          = ["enable-aspect", INFO]
    DISABLE_ASPECT         = ["disable-aspect", INFO]

    ENTER_GENERATED_METHOD = ["enter-generated-method", TRACE]
    EXIT_GENERATED_METHOD  = ["exit-generated-method", TRACE]
    EXIT_BECAUSE_DISABLED  = ["exit-because-disabled", TRACE]
    BEFORE_INVOKE_ADVICE   = ["before-invoke-advice", TRACE]
    AFTER_INVOKE_ADVICE    = ["after-invoke-advice", TRACE]
    BEFORE_WRAPPED_METHOD  = ["before-wrapped-method", TRACE]
    AFTER_WRAPPED_METHOD   = ["after-wrapped-method", TRACE]

    def self.string_to_priority priority_string
      return if priority_string.nil? or priority_string.strip == ''

      case priority_string.downcase
      when 'error' then ERROR
      when 'warn'  then WARN
      when 'info'  then INFO
      when 'debug' then DEBUG
      when 'trace' then TRACE
      end
    end

    def self.init_event_priorities
      @default_visible_priority = TRACE
      @event_priorities = {}
    end

    init_event_priorities

    def self.emit_event? source, priority
      (@event_priorities[source.to_s] || @default_visible_priority) >= priority
    end
  end
end

