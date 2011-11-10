module Aspector
  class DeferredLogic

    attr_reader :code, :value

    def initialize code
      @code = code
    end

    def apply target
      @value = target.class_eval(@code)
    end

  end
end
