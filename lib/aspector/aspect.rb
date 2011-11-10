require 'erb'

module Aspector
  class Aspect

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

    attr_reader :advices, :deferred_logics

    def initialize options = {}, &block
      @options = options
      @advices = []
      instance_eval &block
    end

    def apply target, options = {}
      target = get_target(target)

      aspect_instance = AspectInstance.new(target, self, options)

      @advices.each do |advice|
        next unless advice.advice_block
        target.send :define_method, advice.with_method, advice.advice_block
      end

      target.instance_methods.each do |method|
        advices = advices_for_method method, aspect_instance
        next if advices.empty?

        recreate_method target, method, advices
      end
    end

    def get_target target
      return target if target.is_a?(Module) and not @options[:eigen_class]

      class << target
        self
      end
    end

    def advices_for_method method, context
      @advices.select do |advice|
        advice.match?(method, context)
      end
    end

    def recreate_method target, method, advices
      grouped_advices = []

      advices.each do |advice|
        if advice.around? and not grouped_advices.empty?
          recreate_method_with_advices target, method, grouped_advices

          grouped_advices = []
        end

        grouped_advices << advice
      end

      # create wrap method for before/after advices which are not wrapped inside around advice.
      recreate_method_with_advices target, method, grouped_advices unless grouped_advices.empty?
    end

    def recreate_method_with_advices target, method, advices
      before_advices = advices.select {|advice| advice.before? or advice.before_filter? }
      after_advices  = advices.select {|advice| advice.after?  }
      around_advice  = advices.first if advices.first.around?

      code = METHOD_TEMPLATE.result(binding)
      #puts code
      # line no is the actual line no of METHOD_TEMPLATE + 5
      target.class_eval code, __FILE__, 12
    end

    def before *methods, &block
      @advices << create_advice(Aspector::AdviceMetadata::BEFORE, self, methods, &block)
    end

    def before_filter *methods, &block
      @advices << create_advice(Aspector::AdviceMetadata::BEFORE_FILTER, self, methods, &block)
    end

    def after *methods, &block
      @advices << create_advice(Aspector::AdviceMetadata::AFTER, self, methods, &block)
    end

    def around *methods, &block
      @advices << create_advice(Aspector::AdviceMetadata::AROUND, self, methods, &block)
    end

    def target code
      logic = DeferredLogic.new(code)
      @deferred_logics ||= []
      @deferred_logics << logic
      logic
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

      Aspector::Advice.new(self,
                           meta_data.advice_type,
                           Aspector::MethodMatcher.new(*methods),
                           with_method,
                           options,
                           &block)
    end
  end
end

