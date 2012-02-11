module Aspector
  module ModuleExtension
    Module.send :include, self

    private

    def method_added_aspector method
      return (block_given? and yield) if
        @aop_creating_method or
        @aop_instances.nil? or @aop_instances.empty?

      aspects_applied_flag = :"@aop_applied_#{method}"
      return (block_given? and yield) if instance_variable_get(aspects_applied_flag)

      begin
        instance_variable_set(aspects_applied_flag, true)

        @aop_instances.apply_to_method(method.to_s)

        yield if block_given?
      ensure
        instance_variable_set(aspects_applied_flag, nil)
      end
    end

    def singleton_method_added_aspector method
      # Note: methods involved are on eigen class
      eigen_class = class << self; self; end

      return (block_given? and yield) if eigen_class.instance_variable_get(:@aop_creating_method)

      aspect_instances = eigen_class.instance_variable_get(:@aop_instances)
      return (block_given? and yield) if aspect_instances.nil? or aspect_instances.empty?

      aspects_applied_flag = :"@aop_applied_#{method}"
      return (block_given? and yield) if eigen_class.instance_variable_get(aspects_applied_flag)

      begin
        eigen_class.instance_variable_set(aspects_applied_flag, true)

        aspect_instances.apply_to_method(method.to_s)

        yield if block_given?
      ensure
        eigen_class.instance_variable_set(aspects_applied_flag, nil)
      end
    end

  end
end

