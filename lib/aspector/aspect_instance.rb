module Aspector
  class AspectInstance

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


    def initialize context, aspect, options = {}
      @context = context
      @aspect = aspect
      @options = options

      invoke_deferred_logics
      add_to_instances
      add_hooks
    end

    def deferred_logic_results logic
      @deferred_logic_results[logic]
    end

    def apply_to_methods
      @context.instance_methods.each do |method|
        apply_to_method(method)
      end
    end

    def apply_to_method method
      advices = advices_for_method method
      return if advices.empty?

      recreate_method method, advices
    end

    def to_hash
      { "type" => self.class.name,
        "context" => @context.name,
        "options" => @options,
        "aspect" => @aspect.to_hash
      }
    end

    def to_s
      to_hash.inspect
    end

    private

    def invoke_deferred_logics
      return unless @aspect.deferred_logics

      @deferred_logic_results ||= {}
      @aspect.deferred_logics.each do |logic|
        @deferred_logic_results[logic] = @context.class_eval(logic.code)
      end
    end

    def add_to_instances
      aspect_instances = @context.instance_variable_get(:@aspect_instances)
      unless aspect_instances
        aspect_instances = AspectInstances.new
        @context.instance_variable_set(:@aspect_instances, aspect_instances)
      end
      aspect_instances << self
    end

    def add_hooks
      eigen_class = class << @context; self; end
      orig_method_added = eigen_class.instance_method(:method_added)

      eigen_class.send :define_method, :method_added do |m|
        method_added_aspector(m) do |method|
          orig_method_added.bind(self).call method
        end
      end
    end

    def advices_for_method method
      @aspect.advices.select do |advice|
        advice.match?(method, self)
      end
    end

    def recreate_method method, advices
      @context.instance_variable_set(:@aspector_creating_method, true)
      grouped_advices = []

      advices.each do |advice|
        if advice.around? and not grouped_advices.empty?
          recreate_method_with_advices method, grouped_advices

          grouped_advices = []
        end

        grouped_advices << advice
      end

      # create wrap method for before/after advices which are not wrapped inside around advice.
      recreate_method_with_advices method, grouped_advices unless grouped_advices.empty?
    ensure
      @context.instance_variable_set(:@aspector_creating_method, nil)
    end

    def recreate_method_with_advices method, advices
      before_advices = advices.select {|advice| advice.before? or advice.before_filter? }
      after_advices  = advices.select {|advice| advice.after?  }
      around_advice  = advices.first if advices.first.around?

      code = METHOD_TEMPLATE.result(binding)
      #puts code
      # line no is the actual line no of METHOD_TEMPLATE + 5
      @context.class_eval code, __FILE__, 5
    end

  end
end
