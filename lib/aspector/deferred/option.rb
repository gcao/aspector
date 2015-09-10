module Aspector
  # Module containing elements that are dereffered
  module Deferred
    # Object used to store deferred options that can be used when we create aspects
    # We can use them as a "virtual" attributes that can be used but will be replaced
    # with proper values later on. Thanks to that we may build aspects that are not
    # bind yet to given methods, that are not yet populated with any aspect options, etc
    # This allows us to build better aspects that can be adapted easier to any class/module
    class Option
      attr_reader :key

      # @return [Aspector::Deferred::Option] single deferred option
      # @param key [Symbol] deferred option key that we can provide later
      # @example Create deferred option with a :methods key
      #   Aspector::Deferred::Option.new(:methods) #=> deferred options instance
      def initialize(key = nil)
        @key = key
      end

      # Allows us to reference options that are not yet defined in the aspect
      # @note They will be later on replaced with "normal" options
      # @return [Aspector::Deferred::Option] returns self
      # @param [Symbol] key that we want to retrieve
      #
      # @example Build an after block for methods (options is a deferred option)
      #   before options[:methods] do
      #     values << 'do_this'
      #   end
      def [](key)
        @key = key
        self
      end
    end
  end
end
