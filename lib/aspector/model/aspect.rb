require 'erb'

module Aspector
  module Model
    class Aspect < Array

      METHOD_TEMPLATE = ERB.new <<-CODE
      wrapped_method = instance_method(:<%= method %>)

      define_method :<%= method %> do |*args, &block|
        result = nil

        # Before advices
<% before_advices.each do |definition| %>
<% if definition.options[:method_name_arg] %>
        result = <%= definition.with_method %> '<%= method %>', *args
<% else %>
        result = <%= definition.with_method %> *args
<% end %>

        return result.value if result.is_a? ::Aspector::ReturnThis
<% if definition.options[:skip_if_false] %>
        return unless result
<% end %>
<% end %>

<% if around_advice %>
        # around advice
<%   if around_advice.options[:method_name_arg] %>
        result = <%= around_advice.with_method %> '<%= method %>', *args do |*args|
          wrapped_method.bind(self).call *args, &block
        end
<%   else %>
        result = <%= around_advice.with_method %> *args do |*args|
          wrapped_method.bind(self).call *args, &block
        end
<%   end %>
<% else %>
        # Invoke wrapped method
        result = wrapped_method.bind(self).call *args, &block
<% end %>

        # After advices
<% after_advices.each do |definition| %>
<% if definition.options[:method_name_arg] and definition.options[:result_arg] %>
        result = <%= definition.with_method %> '<%= method %>', result, *args
<% elsif definition.options[:method_name_arg] %>
        <%= definition.with_method %> '<%= method %>', *args
<% elsif definition.options[:result_arg] %>
        result = <%= definition.with_method %> result, *args
<% else %>
        <%= definition.with_method %> *args
<% end %>
<% end %>
        result
      end
      CODE

      def initialize options = {}, &block
        @options = options
        instance_eval &block
      end

      def apply target
        each do |advice|
          next unless advice.advice_block
          target.send :define_method, advice.with_method, advice.advice_block
        end

        target.instance_methods.each do |method|
          advices = advices_for_method method
          next if advices.empty?

          wrap_method target, method, advices
        end
      end

      def advices_for_method method
        select do |advice|
          advice.match?(method)
        end
      end

      def wrap_method target, method, advices
        before_advices = select {|advice| advice.before? or advice.before_filter? }
        after_advices  = select {|advice| advice.after?  }
        around_advice  = first if advices.first.around?

        code = METHOD_TEMPLATE.result(binding)
        #puts code
        # line no is the actual line no of METHOD_TEMPLATE + 5
        target.class_eval code, __FILE__, 12
      end

      def before *methods, &block
        push(create_advice(Aspector::Model::AdviceMetadata::BEFORE, self, methods, &block))
      end

      def before_filter *methods, &block
        push(create_advice(Aspector::Model::AdviceMetadata::BEFORE_FILTER, self, methods, &block))
      end

      def create_advice meta_data, klass_or_module, *methods, &block
        methods.flatten!

        options = meta_data.default_options.clone
        options.merge!(methods.pop) if methods.last.is_a? Hash
        options.merge!(meta_data.mandatory_options)

        # Convert symbols to strings to avoid inconsistencies
        methods.size.times do |i|
          methods[i] = methods[i].to_s if methods[i].is_a? Symbol
        end

        with_method = methods.pop unless block_given?

        Aspector::Model::Advice.new(self,
                                    meta_data.advice_type,
                                    Aspector::Model::MethodMatcher.new(*methods),
                                    with_method,
                                    options,
                                    &block)
      end

    end
  end
end

