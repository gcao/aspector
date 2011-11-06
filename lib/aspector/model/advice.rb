module Aspector
  module Model
    class Advice

      BEFORE = 1
      AFTER  = 2
      AROUND = 3

      attr_reader :type, :method_matcher, :options, :advice_block

      def initialize parent, type, method_matcher, with_method, options = {}, &block
        @parent         = parent
        @type           = type
        @method_matcher = method_matcher
        @with_method    = with_method
        @options        = options
        @advice_block   = block.to_proc if block_given?
      end

      def with_method
        @with_method ||= "aspect_#{@parent.hash}_#{@parent.index(self)}"
      end

      def match? method
        return if method == with_method
        return unless @method_matcher.match?(method)

        return true unless @options[:except]

        @except ||= MethodMatcher.new([@options[:except]].flatten)

        not @except.match?(method)
      end

      def before?
        type == BEFORE and not options[:skip_if_false]
      end

      def before_filter?
        type == BEFORE and options[:skip_if_false]
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

      def to_s
        s = ""
        case @type
        when BEFORE
          if @options[:skip_if_false]
            s << "BEFORE_FILTER: "
          else
            s << "BEFORE: "
          end
        when AFTER
          s << "AFTER : "
        when AROUND
          s << "AROUND: "
        end
        s << "[" << @method_matcher.to_s << "] DO "
        s << @with_method.to_s
        s << " WITH OPTIONS "
        @options.each do |key, value|
          next if key == :skip_if_false
          s << key.to_s << ":" << value.to_s
        end
        s
      end

    end
  end
end
