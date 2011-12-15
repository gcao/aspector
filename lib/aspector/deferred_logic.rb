module Aspector
  class DeferredLogic

    attr_reader :code

    def initialize code
      @code = code
    end

    def apply target, *args
      target.class_exec(*args, &@code)
    end

  end
end
