module Aspector
  class MethodMatcher
    def initialize *match_data
      @match_data = match_data
      @match_data.flatten!
    end

    def match? method, aspect = nil
      @match_data.detect do |item|
        case item
        when String
          item == method
        when Regexp
          item =~ method
        when Symbol
          item.to_s == method
        when DeferredLogic
          value = aspect.deferred_logic_results[item]
          if value
            new_matcher = MethodMatcher.new(*[value].flatten)
            new_matcher.match?(method)
          end
        when DeferredOption
          value = aspect.options[item.key]
          if value
            new_matcher = MethodMatcher.new(value)
            new_matcher.match?(method)
          end
        end
      end
    end

    def has_regular_expressions?
      @has_regexps ||= @match_data.detect { |item| item.is_a? Regexp }
    end

    def to_s
      @match_data.map {|item| item.inspect }.join ", "
    end
  end
end

