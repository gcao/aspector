module Aspector
  # Base aspector class from which each created aspect must inherit
  # It provides all the features to build aspects including a simple Dsl and some additional
  #   class and instance methods
  class Base
    extend Dsl
    extend ClassMethods

    # @return [Boolean] is this aspect enabled
    def enabled?
      self.class.status.enabled?
    end

    # Applies aspect instance into a given target class/module/instance
    # @param target [Class] any object (or class or module) to apply this aspect
    # @param options [Hash] set of options that we can pass to the aspect that will be applied
    # @return [Aspector::Interception] applied interception
    # @example Apply aspect to a ExampleClass
    #   aspect.apply(ExampleClass)
    # @example Apply aspect to an instance
    #   aspect.apply(object, , method: :run)
    # @example Apply aspect to a ExtendingModule
    #   aspect.apply(ExtendingModule, , method: :run)
    def apply(target, options = {})
      Interception.new(
        self,
        target,
        self.class.storage.default_options.merge(options)
      ).apply
    end
  end
end
