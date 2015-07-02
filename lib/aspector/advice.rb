module Aspector
  # A single aspect advice representation
  class Advice
    # All available advices types that we support
    TYPES = %i(
      before
      before_filter
      after
      around
      raw
    )

    # Defines methods that allow us to check if an advice is of a given type
    TYPES.each do |type_name|
      # Defines constants like BEFORE, AFTER,etc
      const_set(type_name.to_s.upcase, type_name)

      # @return [Boolean] is advice of a given type?
      # @example Check if advice is an after
      #   advice.after? #=> true
      define_method :"#{type_name}?" do
        type == type_name
      end
    end

    attr_reader :type, :method_matcher, :options, :advice_code, :advice_block, :name
    attr_accessor :index

    def initialize(parent, type, method_matcher, with_method, options = {}, &block)
      @type = type
      @parent = parent
      @options = options
      @advice_block = block
      @method_matcher = method_matcher
      @name = @options[:name] || "advice_#{index}"

      if with_method.is_a? Symbol
        @with_method = with_method
      else
        @advice_code = with_method
      end
    end

    def with_method
      return nil if @advice_code

      @with_method ||= "aop_#{hash.abs}"
    end

    def match?(method, context = nil)
      return false if method == with_method
      return false unless @method_matcher.match?(method, context)

      return true unless @options[:except]

      @except ||= MethodMatcher.new(@options[:except])

      !@except.match?(method)
    end

    def use_deferred_logic?(logic)
      method_matcher.use_deferred_logic? logic
    end

    def to_s
      s = "#{name}: "
      s << type.to_s.upcase
      s << ' [' << @method_matcher.to_s << '] DO '

      if @with_method
        s << @with_method.to_s
      else
        s << 'stuff in block'
      end
      s << ' WITH OPTIONS ' << @options.inspect
      s
    end
  end
end
