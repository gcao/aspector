module Aspector
  # Metadata object for Advice model
  # It stores informations that are useful when building an advice of a given type
  # Technically it is useful only for the after case when it has some default arguments
  # but we keep it also for the future development, when we might add more types
  class AdviceMetadata
    attr_reader :advice_type, :default_options

    # @param [Symbol] advice_type that we want to build
    # @param [Hash] default_options for given advice type
    # @return [Aspector::AdviceMetadata] medatada informations about given advice type
    # @example Create metadata for :before type
    #   Aspector::AdviceMetadata.new(:before) #=> metadata instance
    # @example Get default metadata for before type
    #   Aspector::AdviceMetadata::BEFORE #=> before metadata instance
    def initialize(advice_type, default_options = {})
      @advice_type = advice_type
      @default_options = default_options
    end

    # Metadata for all the before advices
    BEFORE = new Aspector::Advice::BEFORE
    # Metadata for all the before filter advices
    BEFORE_FILTER = new Aspector::Advice::BEFORE_FILTER
    # Metadata for all the after advices
    AFTER = new Aspector::Advice::AFTER, result_arg: true
    # Metadata for all the around advices
    AROUND = new Aspector::Advice::AROUND
    # Metadata for all the raw advices
    RAW = new Aspector::Advice::RAW
  end
end
