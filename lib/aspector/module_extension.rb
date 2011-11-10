module Aspector
  module ModuleExtension
    # Causes advices applied twice
    #Module.send :include, self

    def method_added_aspector method
      return yield(method) if @aspector_create_method or
                              @aspect_instances.nil? or @aspect_instances.empty? or
                              instance_variable_get(:"@aspects_applied_#{method}")

      begin
        instance_variable_set(:"@aspects_applied_#{method}", true)

        @aspect_instances.apply_to_method(method.to_s)

        yield(method)
      ensure
        instance_variable_set(:"@aspects_applied_#{method}", nil)
      end
    end

    def singleton_method_added_aspector method
      # TODO
    end

  end
end

