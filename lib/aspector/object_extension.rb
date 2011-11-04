module Aspector
  module ObjectExtension

    def aspector target
    end

  end
end

Object.send(:include, Aspector::ObjectExtension)
