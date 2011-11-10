module Aspector
  class MethodMatcher
    def initialize *match_data
      @match_data = match_data
    end

    def match? method, context = nil
      @match_data.detect do |item|
        case item
        when String
          item == method
        when Regexp
          item =~ method
        when Symbol
          item.to_s == method
        when DeferredLogic
          new_matcher = MethodMatcher.new(context.deferred_logic_results[item])
          new_matcher.match?(item)
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

