module Aspector
  module ModuleExtension
    Module.send :include, self

    def method_added_aspector method
      return yield(method) if @aspector_creating_method or
                              @aspect_instances.nil? or @aspect_instances.empty?

      aspects_applied_flag = :"@aspects_applied_#{method}"
      return yield(method) if instance_variable_get(aspects_applied_flag)

      begin
        instance_variable_set(aspects_applied_flag, true)

        @aspect_instances.apply_to_method(method.to_s)

        yield(method)
      ensure
        instance_variable_set(aspects_applied_flag, nil)
      end
    end

    def singleton_method_added_aspector method
      # Note: methods involved are on eigen class
      eigen_class = class << self; self; end

      return yield(method) if eigen_class.instance_variable_get(:@aspector_creating_method)

      aspect_instances = eigen_class.instance_variable_get(:@aspect_instances)
      return yield(method) if aspect_instances.nil? or aspect_instances.empty?

      aspects_applied_flag = :"@aspects_applied_#{method}"
      return yield(method) if eigen_class.instance_variable_get(aspects_applied_flag)

      begin
        eigen_class.instance_variable_set(aspects_applied_flag, true)

        aspect_instances.apply_to_method(method.to_s)

        yield(method)
      ensure
        eigen_class.instance_variable_set(aspects_applied_flag, nil)
      end
    end

  end
end

