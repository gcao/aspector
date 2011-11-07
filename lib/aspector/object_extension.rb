module Aspector
  module ObjectExtension

    def aspector *args, &block
      options = args.last.is_a?(Hash) ? args.pop : {}

      aspect = Aspector::Aspect.new(options, &block)

      aspect.apply(self) if self.is_a? Module
      args.each {|target| aspect.apply(target) }

      aspect
    end

    def Aspector options = {}, &block
      Aspector::Aspect.new(options, &block)
    end

  end
end

Object.send(:include, Aspector::ObjectExtension)
