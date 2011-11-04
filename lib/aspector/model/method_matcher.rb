module Aspector
  module Model
    class MethodMatcher
      def initialize *match_data
        @match_data = match_data

        # Performance improvement ideas:
        #  if there is only one item in match_data, generate simplified match? method on the fly
        #  Seems this does not help much
        #
        # if match_data.size == 1
        #   first_item = match_data.first
        #   eigen_class = class << self; self; end
        #
        #   if first_item.is_a? String
        #     eigen_class.send :define_method, :match? do |method|
        #       method == first_item
        #     end
        #   elsif first_item.is_a? Regexp
        #     eigen_class.send :define_method, :match? do |method|
        #       method =~ first_item
        #     end
        #   else
        #     eigen_class.send :define_method, :match? do |method|
        #       false
        #     end
        #   end
        # end
      end

      def match? method
        @match_data.detect do |item|
          (item.is_a? String and item == method) or
          (item.is_a? Regexp and item =~ method)
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
end

