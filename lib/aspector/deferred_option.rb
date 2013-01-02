module Aspector
  class DeferredOption

    attr_reader :key
    
    def initialize key = nil
      @key = key
    end

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

