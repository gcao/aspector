module Aspector
  class EigenAspect < Aspect

    def real_target target
      class << target; self; end
    end

  end
end
