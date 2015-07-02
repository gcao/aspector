module Aspector
  # Object used to store deferred options
  class DeferredOption
    attr_reader :key

    def initialize(key = nil)
      @key = key
    end

    def [](key)
      @key = key
      self
    end

    def to_s
      "options[#{(key || '?').inspect}]"
    end
  end
end
