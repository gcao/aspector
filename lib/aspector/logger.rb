module Aspector
  # Default logger for Aspector gem
  # @note String joining and logging can be resource consuming, so watch out what you log,
  #   especially when not in debug mode
  class Logger < ::Logger
    attr_reader :context

    # @param context [Aspector::Base, Class] context in which we want to log information
    # @note it will log more details if it is an Aspector internal context
    # @note It will try to detect log level based on ASPECTOR_LOG_LEVEL and will fallback to
    #   ::Logger::ERROR level it if fails
    # @return [Aspector::Logger] logger instance
    def initialize(context)
      super(STDOUT)
      @context = context
      @level = (ENV['ASPECTOR_LOG_LEVEL'] || ::Logger::ERROR).to_i
    end

    # Sets up all the logging methods
    %i( debug info warn error fatal ).each do |level|
      define_method level do |*args|
        # We pass it as a block, so it won't be evaluated unless we really want to log it
        # If we would pass it as a method invocation (not as a block), it would evaluate it
        # even if we would not log it afterwards because the log level doesnt match.
        super(nil) { message(*args) }
      end
    end

    private

    # Creates a full messages that we want to log
    # @param args any arguments that we want to log based on
    # @return [String] message string for logging - provides additional context information
    # @example Create a message based on a single argument
    #   message('action taken') #=> 'Aspector::Base | ExampleClass | action taken'
    def message(*args)
      msg = []

      if context.is_a? Aspector::Base
        msg << context.class.to_s
        msg << context.target.to_s
      else
        msg << context.to_s
      end

      msg += args

      msg.join(' | ')
    end
  end
end
