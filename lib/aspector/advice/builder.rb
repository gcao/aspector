module Aspector
  class Advice
    # Used to build an aspect instance from different set of options
    # When we build an advice, the default API tells us to provide list of arguments from which
    # first we have methods to which we want to apply aspect, and then optional hash options.
    # Here we need to separate those parts, make some additional checking and preparation and
    # then build an Aspector::Advice
    # @note Separating arguments (methods_and_options) into arguments, with_method and options
    #   can be tricky, so before you change anything, please make sure you understand
    #   logic that is behind it
    class Builder
      # @param advice_type [symbol] type of an advice that we want to build (before, after, etc)
      # @param methods_and_options - methods and options based on which we want to create an Advice
      # @param block [Proc] block of code
      # @return [Aspector::Advice::Builder] builder instance
      # @example
      #   Aspector::Advice:Builder.new(
      #     Aspector::Advice::Metadata::BEFORE,
      #     *[:exec, :run, method_args: true, ttl: 1]
      #   )
      def initialize(advice_type, *methods_and_options, &block)
        @meta_data = Aspector::Advice::Metadata.public_send(advice_type)
        @params = Aspector::Advice::Params.new(methods_and_options, block)
        @methods_and_options = methods_and_options.tap(&:flatten!)
        @block = block
      end

      # Builds an Aspector::Advice instance
      # @return [Aspector::Advice] advice instance
      # @raise [Aspector::Errors::CodeBlockRequired] raised when we require a block
      #   of code, but none provided
      # @example
      #   builder.build #=> Aspector::Advice instance
      def build
        fail Errors::CodeBlockRequired if @meta_data.raw? && !@block

        Advice.new(
          @meta_data.advice_type,
          @params.methods,
          @params.with_method,
          @meta_data.default_options.merge(@params.options),
          &@block
        )
      end
    end
  end
end
