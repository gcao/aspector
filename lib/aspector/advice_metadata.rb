module Aspector
  class AdviceMetadata
    attr_reader :advice_type, :default_options, :mandatory_options

    def initialize advice_type, default_options = {}, mandatory_options = {}
      @advice_type       = advice_type
      @default_options   = default_options   || {}
      @mandatory_options = mandatory_options || {}
    end

    BEFORE        = new Aspector::Advice::BEFORE, { :new_methods_only => true }, :skip_if_false => false
    BEFORE_FILTER = new Aspector::Advice::BEFORE, { :new_methods_only => true }, :skip_if_false => true
    AFTER         = new Aspector::Advice::AFTER,  { :new_methods_only => true, :result_arg => true }
    AROUND        = new Aspector::Advice::AROUND, { :new_methods_only => true }
  end
end

