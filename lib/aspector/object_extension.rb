module Aspector
  module ObjectExtension

    private

    def aspector *args, &block
      options = args.last.is_a?(Hash) ? args.pop : {}

      aspect = Aspector(options, &block)

      aspect.aop_apply(self) if self.is_a? Module
      args.each {|target| aspect.aop_apply(target) }

      aspect
    end

    def Aspector options = {}, &block
      klass = Class.new(Aspector::Base)
      klass.aop_default options
      klass.class_eval &block if block_given?
      klass
    end

    def aop_returns value = nil
      throw :aop_returns, value
    end
    alias :returns :aop_returns

  end
end

Object.send(:include, Aspector::ObjectExtension)

