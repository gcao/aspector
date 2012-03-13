module Aspector
  class AspectInstances < Array

    def apply_to_method method
      each do |aspect_instance|
        next if aspect_instance.aop_options[:old_methods_only]
        aspect_instance.aop_apply_to_method method, aspect_instance.aop_advices
      end
    end

  end
end
