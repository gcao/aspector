module Aspector
  class Context

    def initialize(target, aspect_hash, advice_hash)
      @target = target
      @aspect_hash = aspect_hash
      @advice_hash = advice_hash
    end

    def aspect
      @aspect ||= @target.instance_variable_get(:@aspector_instances).detect do |aspect|
        aspect.hash == @aspect_hash
      end
    end

    def advice
      @advice ||= aspect.class.advices.detect { |advice| advice.hash == @advice_hash }
    end

    def options
      aspect.options
    end

  end
end
