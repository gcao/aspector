module Aspector
  class AspectInstance

    def initialize context, aspect, options = {}
      @context = context
      @aspect = aspect
      @options = options

      invoke_deferred_logics

      aspect_instances = context.instance_variable_get(:@aspect_instances)
      unless aspect_instances
        aspect_instances = AspectInstances.new
        context.instance_variable_set(:@aspect_instances, aspect_instances)
      end
      aspect_instances << aspect_instances
    end

    def deferred_logic_results logic
      @deferred_logic_results[logic]
    end

    def invoke_deferred_logics
      return unless @aspect.deferred_logics

      @deferred_logic_results ||= {}
      @aspect.deferred_logics.each do |logic|
        @deferred_logic_results[logic] = @context.class_eval(logic.code)
      end
    end

  end
end
