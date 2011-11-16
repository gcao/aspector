module Aspector
  class DeferredLogic

    attr_reader :code, :value

    def initialize code
      @code = code
    end

    def apply target
      if @code.is_a? String
        @value = target.class_eval(@code)
      else
        @value = target.class_eval(&@code)
      end
    end

  end
end
