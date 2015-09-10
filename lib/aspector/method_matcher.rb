module Aspector
  # Class used to check if a given method matched our match data
  class MethodMatcher
    extend Forwardable

    # The include? will check if we have in match_data a provided item
    def_delegator :@match_data, :include?

    # Raised when we want to match item of a class that we dont support
    class UnsupportedItemClass < StandardError; end

    # @param match_data
    #   [Array<String, Symbol, Regexp, Aspector::DeferredLogic, Aspector::DeferredOption>]
    #   single match details about which method we should match.
    #   As for whole aspector, it can be a string with a method name, symbolized method name,
    #   regexp, deffered logic or deffered option (as a single element)
    # @return [Aspector::MethodMatcher] method matcher instance for given match_data
    # @example Create matcher for a symbol and regexp
    #   Aspector::MethodMatcher.new(:exec, /exil.*/)
    def initialize(*match_data)
      @match_data = match_data.tap(&:flatten!)
    end

    # Informs us if a given method is matched by any of our match data
    # @param [String] method that we want to check
    # @param [Aspector::Interception, nil] optional interception when a match item is a
    #   DeferredLogic or DefferedOption
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
    # @param [String, Symbol, Regexp, Aspector::DeferredLogic, Aspector::DeferredOption]
    #   single match item of a given class
    # @param [String] method that we want to check
    # @param [Aspector::Interception, nil] optional interception when a match item is a
    #   DeferredLogic or DefferedOption
    # @example Check if /exe.*/ matches method
    #   matches?(/exe.*/, 'exec')    #=> true
    #   matches?(/exe.*/, 'ex')      #=> false
    #   matches?(/exe.*/, 'run')     #=> false
    #   matches?(/exe.*/, 'execute') #=> true
    def matches?(match_item, method, aspect = nil)
      case match_item
      when String
        match_item == method
      when Regexp
        !(match_item =~ method).nil?
      when Symbol
        match_item.to_s == method
      when DeferredLogic
        value = aspect.deferred_logic_results(match_item)
        return false unless value

        self.class.new(value).any?(method)
      when DeferredOption
        value = aspect.options[match_item.key]
        return false unless value

        self.class.new(value).any?(method)
      else
        fail UnsupportedItemClass, match_item.class
      end
    end
  end
end
