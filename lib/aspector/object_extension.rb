module Aspector
  module ObjectExtension

    def aspector *args, &block
      Helper.handle_aspect self, *args, &block
    end

  end
end

Object.send(:include, Aspector::ObjectExtension)
