module Aspector
  class DeferredOption

    attr_reader :key

    def [] key
      @key = key
      self
    end

    def to_s
      if key
        "options[#{key.inspect}]"
      else
        "options[?]"
      end
    end
  end
end

