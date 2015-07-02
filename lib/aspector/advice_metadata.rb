module Aspector
  # Metadata for Advice model
  class AdviceMetadata
    attr_reader :advice_type, :default_options

    def initialize(advice_type, default_options = {})
      @advice_type = advice_type
      @default_options = default_options
    end

    BEFORE        = new Aspector::Advice::BEFORE
    BEFORE_FILTER = new Aspector::Advice::BEFORE_FILTER
    AFTER         = new Aspector::Advice::AFTER, result_arg: true
    AROUND        = new Aspector::Advice::AROUND
    RAW           = new Aspector::Advice::RAW
  end
end
