module Aspector
  class Advice

    BEFORE = 1
    AFTER  = 2
    AROUND = 3
    RAW    = 4

    attr_reader :type, :method_matcher, :options, :advice_block
    attr_accessor :index

    def initialize parent, type, method_matcher, with_method, options = {}, &block
      @parent         = parent
      @type           = type
      @method_matcher = method_matcher
      @with_method    = with_method
      @options        = options
      @advice_block   = block
    end

    def name
      @options[:name] || "advice #{index}"
    end

    def with_method
      @with_method ||= "aop_#{hash.abs}"
    end

    def match? method, context = nil
      return if method == with_method
      return unless @method_matcher.match?(method, context)

      return true unless @options[:except]

      @except ||= MethodMatcher.new(@options[:except])

      not @except.match?(method)
    end

    def raw?
      type == RAW
    end

    def before?
      type == BEFORE
    end

    def after?
      type == AFTER
    end

    def around?
      type == AROUND
    end

    def invoke obj, *args, &block
      obj.send with_method, *args, &block
    end

    def type_name
      case @type
      when BEFORE then @options[:skip_if_false] ? "BEFORE_FILTER" : "BEFORE"
      when AFTER  then "AFTER"
      when AROUND then "AROUND"
      when RAW    then "RAW"
      else "UNKNOWN?!"
      end
    end

    def to_s
      s = "#{name}: "
      s << type_name
      s << " [" << @method_matcher.to_s << "] DO "
      if @with_method
        s << @with_method.to_s
      else
        s << "stuff in block"
      end
      s << " WITH OPTIONS " << @options.inspect
      s
    end

  end
end
