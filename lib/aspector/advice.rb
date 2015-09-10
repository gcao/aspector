module Aspector
  # A representation of a given type of advice
  class Advice
    # All available advices types that we support
    TYPES = %i(
      before
      before_filter
      after
      around
      raw
    )

    # What prefix should generated methods have
    METHOD_PREFIX = 'aspector_advice'

    attr_reader :options, :advice_code, :advice_block, :with_method

    # Defines methods that allow us to check if an advice is of a given type
    TYPES.each do |type_name|
      # Defines constants like BEFORE, AFTER,etc
      const_set(type_name.to_s.upcase, type_name)

      # @return [Boolean] is advice of a given type?
      # @example Check if advice is an after, before or before_filter
      #   advice.after?         #=> true
      #   advice.before?        #=> false
      #   advice.before_filter? #=> false
      define_method :"#{type_name}?" do
        @type == type_name
      end
    end

    # @param type [Symbol] type of advice that we want to build (see TYPES)
    # @param match_methods [Array<Symbol, String, Regexp, Deferred::Logic, Deferred::Option>]
    #   methods and other elements that we want to match
    # @param with_method [Symbol, nil] method name what should be invoked (or nil if block should
    #   be invoked)
    # @param options [Hash] hash with options for this advice
    # @param block [Proc, nil] block that should be invoked - not required if
    #   with_method is not nil
    # @raise [Aspector::Errors::InvalidAdviceType] raised when we want to create an advice of a
    #   type that is not supported
    # @raise [Aspector::Errors::CodeBlockRequired] raised when we dont provide with_method or block
    def initialize(type, match_methods, with_method, options = {}, &block)
      # Proceed only with supported advices types
      fail Errors::InvalidAdviceType, type unless TYPES.include?(type)
      # Proceed only when theres a with_method or a block that we will apply
      fail Errors::CodeBlockRequired unless with_method || block

      @type = type
      @options = options
      @advice_block = block
      @method_matcher = MethodMatcher.new(*match_methods)

      if with_method.is_a? Symbol
        @with_method = with_method
      else
        @advice_code = with_method
        @with_method = "#{METHOD_PREFIX}_#{object_id}"
      end
    end

    # @param method [String] name of a method that we want to check
    # @param interception [Aspector::Interception] interception that provides us with a context in
    #   which we check for method mathing
    # @return [Boolean] true if provided method matches and we can apply advice to it
    def match?(method, interception)
      # If nothing in the provided matcher matches, we need to quit
      return false unless @method_matcher.any?(method, interception)
      # If it matches and there are no exceptions - it means we should match
      return true unless @options[:except]

      # We have to create a second matcher here, tu check the exceptations
      @except ||= MethodMatcher.new(@options[:except])

      !@except.any?(method)
    end

    # @param logic [Aspector::Deferred::Logic] deferred logic that we want to use
    # @return [Boolean] should it use this logic
    def use_deferred_logic?(logic)
      @method_matcher.include?(logic)
    end
  end
end
