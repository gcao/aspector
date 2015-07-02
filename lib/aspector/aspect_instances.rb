module Aspector
  class AspectInstances < Array
    def apply_to_method method
      each do |aspect_instance|
        next if aspect_instance.options[:existing_methods_only]

        aspect_instance.apply_to_method method
      end
    end
  end
end
