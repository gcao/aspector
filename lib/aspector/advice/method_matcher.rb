module Aspector
  class Advice
    # Class used to check if a given method matched our match data
    # @note It is used internally in the advice class only
    class MethodMatcher
      extend Forwardable

      # The include? will check if we have in match_data a provided item
      def_delegator :@match_data, :include?

      # @param match_data
      #   [Array<String, Symbol, Regexp, Aspector::Deferred::Logic, Aspector::Deferred::Option>]
      #   single match details about which method we should match.
      #   As for whole aspector, it can be a string with a method name, symbolized method name,
      #   regexp, deffered logic or deffered option (as a single element)
      # @return [Aspector::Advice::MethodMatcher] method matcher instance for given match_data
      # @example Create matcher for a symbol and regexp
      #   Aspector::Advice::MethodMatcher.new(:exec, /exil.*/)
      def initialize(*match_data)
        @match_data = match_data.tap(&:flatten!)
      end

      # Informs us if a given method is matched by any of our match data
      # @param method [String] method that we want to check
      # @param aspect [Aspector::Interception, nil] optional interception when a match item is a
      #   Deferred::Logic or DefferedOption
      # @return [Boolean] does a given method match our match_data
      # @example check if method matches either :calculate or /subst.*/
      #   any?('substract')  #=> true
      #   any?('sub')        #=> false
      #   any?('calculate!') #=> false
      #   any?('calculate')  #=> true
      def any?(method, aspect = nil)
        @match_data.any? do |item|
          matches?(item, method, aspect)
        end
      end

      # @return [String] stringed list of all elements that were in match_data
      # @example Print this method_matcher
      #   method_matcher.to_s #=> 'execution, run, (?-mix:a.*)'
      def to_s
        @match_data.map(&:inspect).join(', ')
      end

      private

      # @return [Boolean] checks if a match_item matches a given method
      # @param match_item
      #   [String, Symbol, Regexp, Aspector::Deferred::Logic, Aspector::Deferred::Option]
      #   single match item of a given class
      # @param method [String] method that we want to check
      # @param interception [Aspector::Interception, nil] optional interception when
      #   a match item is a Deferred::Logic or DefferedOption
      # @example Check if /exe.*/ matches method
      #   matches?(/exe.*/, 'exec')    #=> true
      #   matches?(/exe.*/, 'ex')      #=> false
      #   matches?(/exe.*/, 'run')     #=> false
      #   matches?(/exe.*/, 'execute') #=> true
      def matches?(match_item, method, interception = nil)
        case match_item
        when String
          match_item == method
        when Regexp
          !(match_item =~ method).nil?
        when Symbol
          match_item.to_s == method
        when Deferred::Logic
          matches_deferred_logic?(match_item, method, interception)
        when Deferred::Option
          matches_deferred_option?(match_item, method, interception)
        else
          fail Errors::UnsupportedItemClass, match_item.class
        end
      end

      # @return [Boolean] checks if a deferred logic match item matches the method
      # @param match_item [Aspector::Deferred::Logic] deferred logic over which we match
      # @param method [String] method that we want to check
      # @param interception [Aspector::Interception] interception that owns the deferred logic
      def matches_deferred_logic?(match_item, method, interception)
        value = interception.deferred_logic_results(match_item)
        return false unless value

        self.class.new(value).any?(method)
      end

      # @return [Boolean] checks if a deferred option match item matches the method
      # @param match_item [Aspector::Deferred::Option] deferred option over which we match
      # @param method [String] method that we want to check
      # @param interception [Aspector::Interception] interception that owns the deferred option
      def matches_deferred_option?(match_item, method, interception)
        value = interception.options[match_item.key]
        return false unless value

        self.class.new(value).any?(method)
      end
    end
  end
end
