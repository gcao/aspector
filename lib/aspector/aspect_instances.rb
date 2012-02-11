module Aspector
  class AspectInstances < Array

    def apply_to_method method
      each do |aspect_instance|
        aspect_instance.send :_apply_to_method_, method
      end
    end

  end
end
