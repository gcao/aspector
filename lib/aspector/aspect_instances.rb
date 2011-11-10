module Aspector
  class AspectInstances < Array

    def apply_to_method method
      each do |aspect_instance|
        aspect_instance.apply_to_method(method)
      end
    end

  end
end
