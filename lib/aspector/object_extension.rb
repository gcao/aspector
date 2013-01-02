module Aspector
  module ObjectExtension

    private

    def aspector *args, &block
      options = args.last.is_a?(Hash) ? args.pop : {}

      aspect = Aspector(options, &block)

      aspect.apply(self) if self.is_a? Module
      args.each {|target| aspect.apply(target) }

      aspect
    end

    def Aspector options = {}, &block
      klass = Class.new(Aspector::Base)
      klass.class_eval { default options }
      klass.class_eval &block if block_given?
      klass
    end

    def returns value = nil
      throw :returns, value
    end
    alias :returns :returns

  end
end

Object.send(:include, Aspector::ObjectExtension)

