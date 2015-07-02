module Aspector
  # Default logger for Aspector
  # @note It uses ::Logger features - providing basic logging
  class Logger < ::Logger
    attr_reader :context

    def initialize(context)
      super(STDOUT)
      @context = context
      @level = (ENV['ASPECTOR_LOG_LEVEL'] || ::Logger::ERROR).to_i
    end

    %i( debug info warn error fatal ).each do |level|
      define_method level do |*args|
        super -> { postfix(*args) }
      end
    end

    private

    def postfix(*args)
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
