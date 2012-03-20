require 'erb'

module Aspector
  class Base

    attr :aop_options
    alias :options :aop_options

    attr :aop_wrapped_methods

    def initialize target, options = {}
      @aop_target = target

      default_options = self.class.aop_default_options
      if default_options and not default_options.empty?
        @aop_options = default_options.merge(options)
      else
        @aop_options = options
      end

      # @aop_context is where advices will be applied (i.e. where methods are modified), can be different from target
      @aop_context = aop_get_context

      @aop_wrapped_methods = {}

      after_initialize
    end

    def aop_enable
      class << self
        def aop_disabled?; end
      end

      aop_disabled?
    end
    alias enable aop_enable

    def aop_disable
      class << self
        def aop_disabled?; true; end
      end

      aop_disabled?
    end
    alias disable aop_disable

    def aop_reset_disabled
      class << self
        remove_method :aop_disabled?
      end

      aop_disabled?
    end
    alias reset_disabled :aop_reset_disabled

    def aop_disabled?
    end

    def disabled?
      aop_disabled?
    end

    def aop_advices
      self.class.aop_advices
    end
    alias :advices :aop_advices

    def aop_apply
      before_apply
      aop_invoke_deferred_logics
      aop_define_methods_for_advice_blocks
      aop_add_to_instances unless @aop_options[:old_methods_only]
      aop_apply_to_methods unless @aop_options[:new_methods_only]
      aop_add_method_hooks unless @aop_options[:old_methods_only]
      after_apply
    end
    alias :apply :aop_apply

    def aop_apply_to_methods
      advices = aop_advices

      # If method/methods option is set and all are String or Symbol, apply to those only, instead of
      # iterating through all methods
      methods = [@aop_options[:method] || @aop_options[:methods]]
      methods.compact!
      methods.flatten!

      if not methods.empty? and methods.all?{|method| method.is_a? String or method.is_a? Symbol }
        methods.each do |method|
          aop_apply_to_method(method.to_s, advices)
        end

        return
      end

      @aop_context.public_instance_methods.each do |method|
        aop_apply_to_method(method.to_s, advices, :public)
      end

      @aop_context.protected_instance_methods.each do |method|
        aop_apply_to_method(method.to_s, advices, :protected)
      end

      if @aop_options[:private_methods]
        @aop_context.private_instance_methods.each do |method|
          aop_apply_to_method(method.to_s, advices, :private)
        end
      end
    end

    def aop_apply_to_method method, advices, scope = nil
      advices = aop_filter_advices advices, method
      return if advices.empty?

      before_apply_to_method method, advices

      scope ||=
          if @aop_context.private_instance_methods.include?(RUBY_VERSION.index('1.9') ? method.to_sym : method.to_s)
            :private
          elsif @aop_context.protected_instance_methods.include?(RUBY_VERSION.index('1.9') ? method.to_sym : method.to_s)
            :protected
          else
            :public
          end

      aop_recreate_method method, advices, scope

      after_apply_to_method method, advices
    end

    protected

    # Hook method that runs after an aspect is instantiated
    def after_initialize
    end

    # Hook method that runs before an aspect is applied
    def before_apply
    end

    # Hook method that runs after an aspect is applied
    def after_apply
    end

    def before_apply_to_method method, advices
    end

    def after_apply_to_method method, advices
    end

    private

    def aop_deferred_logic_results logic
      @aop_deferred_logic_results[logic]
    end

    def aop_get_context
      return @aop_target if @aop_target.is_a?(Module) and not @aop_options[:class_methods]

      class << @aop_target
        self
      end
    end

    def aop_invoke_deferred_logics
      return unless (logics = self.class.send :aop_deferred_logics)

      @aop_deferred_logic_results ||= {}
      logics.each do |logic|
        @aop_deferred_logic_results[logic] = logic.apply @aop_context, self
      end
    end

    def aop_define_methods_for_advice_blocks
      aop_advices.each do |advice|
        next unless advice.advice_block
        @aop_context.send :define_method, advice.with_method, advice.advice_block
        @aop_context.send :private, advice.with_method
      end
    end

    def aop_add_to_instances
      aspect_instances = @aop_context.instance_variable_get(:@aop_instances)
      unless aspect_instances
        aspect_instances = AspectInstances.new
        @aop_context.instance_variable_set(:@aop_instances, aspect_instances)
      end
      aspect_instances << self
    end

    def aop_add_method_hooks
      if @aop_options[:class_methods]
        return unless @aop_target.is_a?(Module)

        eigen_class = class << @aop_target; self; end
        orig_singleton_method_added = @aop_target.method(:singleton_method_added)

        eigen_class.send :define_method, :singleton_method_added do |method|
          aop_singleton_method_added(method) do
            orig_singleton_method_added.call(method)
          end
        end
      else
        eigen_class = class << @aop_target; self; end

        if @aop_target.is_a? Module
          orig_method_added = @aop_target.method(:method_added)
        else
          orig_method_added = eigen_class.method(:method_added)
        end

        eigen_class.send :define_method, :method_added do |method|
          aop_method_added(method) do
            orig_method_added.call(method)
          end
        end
      end
    end

    def aop_filter_advices advices, method
      advices.select do |advice|
        advice.match?(method, self)
      end
    end

    def aop_recreate_method method, advices, scope
      @aop_wrapped_methods[method] = @aop_context.instance_method(method)
      @aop_context.instance_variable_set(:@aop_creating_method, true)

      before_advices = advices.select {|advice| advice.before? }
      after_advices  = advices.select {|advice| advice.after?  }
      around_advices = advices.select {|advice| advice.around? }

      (around_advices.size - 1).downto(1) do |i|
        advice = around_advices[i]
        aop_recreate_method_with_advices method, [], [], advice
      end

      aop_recreate_method_with_advices method, before_advices, after_advices, around_advices.first, true

      @aop_context.send scope, method if scope != :public
    ensure
      @aop_context.instance_variable_set(:@aop_creating_method, nil)
    end

    def aop_recreate_method_with_advices method, before_advices, after_advices, around_advice, is_outermost = false
      aspect = self

      code = METHOD_TEMPLATE.result(binding)
      #puts code
      @aop_context.class_eval code, __FILE__, __LINE__ + 4
    end

    METHOD_TEMPLATE = ERB.new <<-CODE
    orig_method = aspect.aop_wrapped_methods['<%= method %>']

<% if around_advice %>
    wrapped_method = instance_method(:<%= method %>)
<% end %>

    define_method :<%= method %> do |*args, &block|
      return orig_method.bind(self).call(*args, &block) if aspect.aop_disabled?

<% if is_outermost %>
      catch(:aop_returns) do
<% end %>

      # Before advices
<% before_advices.each do |advice| %>
      result = <%= advice.with_method %> <%
        if advice.options[:aspect_arg] %>aspect, <% end %><%
        if advice.options[:method_arg] %>'<%= method %>', <% end
        %>*args

<%  if advice.options[:skip_if_false] %>
      return unless result
<%  end
  end
%>

<% if around_advice %>
      # Around advice
      result = <%= around_advice.with_method %> <%
        if around_advice.options[:aspect_arg] %>aspect, <% end %><%
        if around_advice.options[:method_arg] %>'<%= method %>', <% end
        %>wrapped_method.bind(self), *args, &block
<% else %>
      # Invoke original method
      result = orig_method.bind(self).call *args, &block
<% end %>

      # After advices
<% unless after_advices.empty?
    after_advices.each do |advice|
      if advice.options[:result_arg]
%>
      result = <%= advice.with_method %> <%
        if advice.options[:aspect_arg] %>aspect, <% end %><%
        if advice.options[:method_arg] %>'<%= method %>', <% end %><%
        if advice.options[:result_arg] %>result, <% end
        %>*args
<%    else %>
      <%= advice.with_method %> <%
        if advice.options[:aspect_arg] %>aspect, <% end %><%
        if advice.options[:method_arg] %>'<%= method %>', <% end
        %>*args
<%    end
    end
%>
      result
<% end %>

<% if is_outermost %>
      end
<% end %>
    end
    CODE

  end
end

