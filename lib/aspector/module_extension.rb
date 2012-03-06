module Aspector
  module ModuleExtension
    Module.send :include, self

    private

    def aop_method_added method
      return (block_given? and yield) if
        @aop_creating_method or
        @aop_instances.nil? or @aop_instances.empty?

      aop_applied_flag = :"@aop_applied_#{method}"
      return (block_given? and yield) if instance_variable_get(aop_applied_flag)

      begin
        instance_variable_set(aop_applied_flag, true)

        @aop_instances.apply_to_method(method.to_s)

        yield if block_given?
      ensure
        instance_variable_set(aop_applied_flag, nil)
      end
    end

    def aop_singleton_method_added method
      # Note: methods involved are on eigen class
      eigen_class = class << self; self; end

      return (block_given? and yield) if eigen_class.instance_variable_get(:@aop_creating_method)

      aop_instances = eigen_class.instance_variable_get(:@aop_instances)
      return (block_given? and yield) if aop_instances.nil? or aop_instances.empty?

      aop_applied_flag = :"@aop_applied_#{method}"
      return (block_given? and yield) if eigen_class.instance_variable_get(aop_applied_flag)

      begin
        eigen_class.instance_variable_set(aop_applied_flag, true)

        aop_instances.apply_to_method(method.to_s)

        yield if block_given?
      ensure
        eigen_class.instance_variable_set(aop_applied_flag, nil)
      end
    end

  end
end

