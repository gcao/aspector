module Aspector
  module Model
    class AdviceMetadata
      attr_reader :advice_type, :default_options, :mandatory_options

      def initialize advice_type, default_options = {}, mandatory_options = {}
        @advice_type       = advice_type
        @default_options   = default_options   || {}
        @mandatory_options = mandatory_options || {}
      end

      def with_method_prefix
        case advice_type
        when Aspector::Model::Advice::BEFORE then "aor_before_"
        when Aspector::Model::Advice::AFTER  then "aor_after_"
        when Aspector::Model::Advice::AROUND then "aor_around_"
        else raise "Aspector internal error."
        end
      end

      BEFORE        = new Aspector::Model::Advice::BEFORE, { :new_methods_only => true }, :skip_if_false => false
      BEFORE_FILTER = new Aspector::Model::Advice::BEFORE, { :new_methods_only => true }, :skip_if_false => true
      AFTER         = new Aspector::Model::Advice::AFTER,  { :new_methods_only => true, :result_arg => true }
      AROUND        = new Aspector::Model::Advice::AROUND, { :new_methods_only => true }
    end
  end
end

