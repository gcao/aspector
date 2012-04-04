module Aspector
  class AdviceMetadata
    attr_reader :advice_type, :default_options, :mandatory_options

    def initialize advice_type, default_options, mandatory_options
      @advice_type       = advice_type
      @default_options   = default_options   || {}
      @mandatory_options = mandatory_options || {}
    end

    BEFORE        = new Aspector::Advice::BEFORE, nil, :skip_if_false => false
    BEFORE_FILTER = new Aspector::Advice::BEFORE, nil, :skip_if_false => true
    AFTER         = new Aspector::Advice::AFTER,  { :result_arg => true }, nil
    AROUND        = new Aspector::Advice::AROUND, nil, nil
    RAW           = new Aspector::Advice::RAW, nil, nil
  end
end

