require 'erb'

module Aspector
  class Base

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

    def to_hash
      {
        "type" => self.class.name,
        "context" => @context.name,
        "options" => @options,
        "aspect" => self.class.to_hash
      }
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
      # line no is the actual line no of METHOD_TEMPLATE + 5
      @context.class_eval code, __FILE__, 7
    end

    class << self

      def advices
        @advices ||= []
      end

      def options
        @options ||= {}
      end

      def deferred_logics
        @deferred_logics ||= []
      end

      def apply target, options = {}
        instances = target.instance_variable_get(:@aspector_instances)
        return if instances and instances.detect {|instance| instance.is_a?(self) }

        aspect_instance = new(target, options)
        aspect_instance.apply
      end

      def default options
        if @options
          @options.merge! options
        else
          @options = options
        end
      end

      def before *methods, &block
        advices << create_advice(Aspector::AdviceMetadata::BEFORE, self, methods, &block)
      end

      def before_filter *methods, &block
        advices << create_advice(Aspector::AdviceMetadata::BEFORE_FILTER, self, methods, &block)
      end

      def after *methods, &block
        advices << create_advice(Aspector::AdviceMetadata::AFTER, self, methods, &block)
      end

      def around *methods, &block
        advices << create_advice(Aspector::AdviceMetadata::AROUND, self, methods, &block)
      end

      def target code = nil, &block
        logic = DeferredLogic.new(code || block)
        deferred_logics << logic
        logic
      end

      def deferred_option key
        DeferredOption.new(key)
      end

      def to_hash
        {
          "type" => self.name,
          "options" => options,
          "advices" => advices.map {|advice| advice.to_s }
        }
      end

      private

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
end

