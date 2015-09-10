module Aspector
  class Advice
    # Allows extracting methods and additional options from single array
    # When we build an advice, the default API tells us to provide list of arguments from which
    # first we have methods to which we want to apply aspect, and then optional hash options.
    # Here we need to separate those parts, make some additional checking and preparation and
    # then build an Aspector::Advice
    # @note Separating arguments (methods_and_options) into arguments, with_method and options
    #   can be tricky, so before you change anything, please make sure you understand
    #   logic that is behind it
    class Params
      def initialize(methods_and_options, block)
        @methods_and_options = methods_and_options.tap(&:flatten!)
        @block = block
      end

      # @return [Hash] hash with options for advice that we are creating
      # @note This will use default options for a given advice and will merge to it any
      #   optional options provided in @meta_data hash
      # @example No options in the @meta_data
      #   @meta_data = [:exec]
      #   options #=> only default aspect metadata options
      # @example Options in the @meta_data
      #   @meta_data = [:exec, { ttl: 10 }]
      #   options #=> { result_arg: true, ttl: 10 } // Hash with default options + options
      def options
        options? ? @methods_and_options.last : {}
      end

      # @return [Symbol, String, nil] with_method that should be executed when aspect is used
      # @example Methods names, no block and options
      #   @methods_and_options = [:exec, /exe.*/, :before_exe, { method_arg: true }]
      #   @block = nil
      #   with_method #=> :before_exec
      # @example Methods names and nothing else
      #   @methods_and_options = [:exec, :run]
      #   @block = nil
      #   with_method #=> :run
      # @example Methods names and options (no block)
      #   @methods_and_options = [:exec, :run, { ttl: 1 }]
      #   @block = nil
      #   with_method #=> :run
      # @example Everything including block
      #   @methods_and_options = [:exec, :run, { ttl: 1 }]
      #   @block = -> {}
      #   with_method #=> nil
      def with_method
        # If we've provided a block, there can't be a with_method. We assume that all
        # method names are methods to which we should bind with the aspect advice
        return nil unless with_method?
        # If there's no block given and there are no options (which should be as a last arg)
        # we assume that the last method is the method that should be executed
        return @methods_and_options.last unless options?

        # If we're here than it means that there were no block and there are options
        # It means that in the @methods_and_options we have both with_method and options
        # so with_method name is before all options (that are last)
        @methods_and_options[@methods_and_options.size - 2]
      end

      # @return [Array<String, Regexp>] formatted array with list of methods for which we should
      #   apply the aspect
      # @note For consistancy all symbol method names will be casted to strings
      def methods
        methods = extracted_methods

        methods.map! do |method|
          method.is_a?(Symbol) ? method.to_s : method
        end

        methods += [
          Deferred::Option.new(:method),
          Deferred::Option.new(:methods)
        ] if methods.empty?

        methods
      end

      private

      # @return [Boolean] true if there's no block provided. It means that we should take
      #   the last method name from the @methods_and_options (not the last element but
      #   last string/symbol) and assume that this is a method that should be executed
      #   when aspect is being used
      # @example
      #   @methods_and_options = [:exec, /exe.*/, :before_exe, { method_arg: true }]
      #   @block = nil
      #   with_method? #=> true
      #   with_method #=> :before_exec
      def with_method?
        @block.nil?
      end

      # @return [Boolean] true if we have options in methods_and_options variable
      # @note Those are the optional options provided as a last argument for
      #   DSL building methods (before, after, etc)
      def options?
        @methods_and_options.last.is_a? Hash
      end

      # Extracts methods for which we should apply the aspect
      # @note This just extracts them from the @methods_and_options, further processing happens
      #   in the '#methods' method
      def extracted_methods
        # If there are no extra options and there is a block of code, then the @methods_and_options
        # is composed only from methods to which we should apply the aspect
        return @methods_and_options if !options? && !with_method?
        # If there are options and no block, it means that two last parameters in the array are
        # the method that should be executed on the aspect and aspect options
        return @methods_and_options[0...-2] if options? && with_method?
        # Otherwise it means that we have a block and options
        @methods_and_options[0...-1]
      end
    end
  end
end
