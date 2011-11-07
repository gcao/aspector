module Aspector
  class EigenAspect < AbstractAspect

    def real_target target
      class << target; self; end
    end

  end
end
