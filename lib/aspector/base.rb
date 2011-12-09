require 'erb'

module Aspector
  class Base

    attr :options

    def initialize target, options = {}
      @target = target
      @options = options.merge(self.class.options)
      @context = get_context # Context is where advices will be applied (i.e. where methods are modified)
    end

    def apply
      invoke_deferred_logics
      define_methods_for_advice_blocks
      add_to_instances
      apply_to_methods
      add_method_hooks
    end

    def deferred_logic_results logic
      @deferred_logic_results[logic]
    end

    def apply_to_methods
      @context.public_instance_methods.each do |method|
        apply_to_method(method, :public)
      end

      @context.protected_instance_methods.each do |method|
        apply_to_method(method, :protected)
      end

      if @options[:private_methods]
        @context.private_instance_methods.each do |method|
          apply_to_method(method, :private)
        end
      end
    end

    def apply_to_method method, scope = nil
      advices = advices_for_method method
      return if advices.empty?

      scope ||=
        if @context.private_instance_methods.include?(method.to_s)
          :private
        elsif @context.protected_instance_methods.include?(method.to_s)
          :protected
        else
          :public
        end

      recreate_method method, advices, scope
    end

    private

    def get_context
      return @target if @target.is_a?(Module) and not @options[:eigen_class]

      class << @target
        self
      end
    end

    def invoke_deferred_logics
      return unless self.class.deferred_logics

      @deferred_logic_results ||= {}
      self.class.deferred_logics.each do |logic|
        @deferred_logic_results[logic] = logic.apply @context
      end
    end

    def define_methods_for_advice_blocks
      self.class.advices.each do |advice|
        next unless advice.advice_block
        @context.send :define_method, advice.with_method, advice.advice_block
        @context.send :private, advice.with_method
      end
    end

    def add_to_instances
      aspect_instances = @context.instance_variable_get(:@aspector_instances)
      unless aspect_instances
        aspect_instances = AspectInstances.new
        @context.instance_variable_set(:@aspector_instances, aspect_instances)
      end
      aspect_instances << self
    end

    def add_method_hooks
      if @options[:eigen_class]
        return unless @target.is_a?(Module)

        eigen_class = class << @target; self; end
        orig_singleton_method_added = @target.method(:singleton_method_added)

        eigen_class.send :define_method, :singleton_method_added do |method|
          singleton_method_added_aspector(method) do
            orig_singleton_method_added.call(method)
          end
        end
      else
        eigen_class = class << @target; self; end

        if @target.is_a? Module
          orig_method_added = @target.method(:method_added)
        else
          orig_method_added = eigen_class.method(:method_added)
        end

        eigen_class.send :define_method, :method_added do |method|
          method_added_aspector(method) do
            orig_method_added.call(method)
          end
        end
      end
    end

    def advices_for_method method
      self.class.advices.select do |advice|
        advice.match?(method, self)
      end
    end

    def recreate_method method, advices, scope
      @context.instance_variable_set(:@aspector_creating_method, true)

      before_advices = advices.select {|advice| advice.before? or advice.before_filter? }
      after_advices  = advices.select {|advice| advice.after? }
      around_advices = advices.select {|advice| advice.around? }

      if around_advices.size > 1
        (around_advices.size - 1).downto(1) do |i|
          advice = around_advices[i]
          recreate_method_with_advices method, [], [], advice
        end
      end

      recreate_method_with_advices method, before_advices, after_advices, around_advices.first

      @context.send scope, method if scope != :public
    ensure
      @context.instance_variable_set(:@aspector_creating_method, nil)
    end

    def recreate_method_with_advices method, before_advices, after_advices, around_advice
      code = METHOD_TEMPLATE.result(binding)
      #puts code
      @context.class_eval code, __FILE__, __LINE__ + 4
    end

    METHOD_TEMPLATE = ERB.new <<-CODE
    target = self
    wrapped_method = instance_method(:<%= method %>)

    define_method :<%= method %> do |*args, &block|
      result = nil

      # Before advices
<% before_advices.each do |advice| %>
<% if advice.options[:context_arg] %>
      context = Aspector::Context.new(target, <%= self.hash %>, <%= advice.hash %>)
      result = <%= advice.with_method %> context, *args
<% else %>
      result = <%= advice.with_method %> *args
<% end %>

      return result.value if result.is_a? ::Aspector::ReturnThis
<% if advice.options[:skip_if_false] %>
      return unless result
<% end %>
<% end %>

<% if around_advice %>
      # around advice
<%   if around_advice.options[:context_arg] %>
      context = Aspector::Context.new(target, <%= self.hash %>, <%= around_advice.hash %>)
      result = <%= around_advice.with_method %> context, *args do |*args|
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
<% after_advices.each do |advice| %>
<% if advice.options[:context_arg] and advice.options[:result_arg] %>
      context = Aspector::Context.new(target, <%= self.hash %>, <%= advice.hash %>)
      result = <%= advice.with_method %> context, result, *args
<% elsif advice.options[:context_arg] %>
      <%= advice.with_method %> context, *args
<% elsif advice.options[:result_arg] %>
      result = <%= advice.with_method %> result, *args
<% else %>
      <%= advice.with_method %> *args
<% end %>
<% end %>
      result
    end
    CODE

  end
end

