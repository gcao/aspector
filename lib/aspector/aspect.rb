require 'erb'

module Aspector
  class Aspect

    attr_reader :advices, :options, :deferred_logics

    def initialize options = {}, &block
      @options = options
      @advices = []
      instance_eval &block
    end

    def apply target, options = {}
      aspect_instance = AspectInstance.new(target, self, options)
      aspect_instance.apply
    end

    def before *methods, &block
      @advices << create_advice(Aspector::AdviceMetadata::BEFORE, self, methods, &block)
    end

    def before_filter *methods, &block
      @advices << create_advice(Aspector::AdviceMetadata::BEFORE_FILTER, self, methods, &block)
    end

    def after *methods, &block
      @advices << create_advice(Aspector::AdviceMetadata::AFTER, self, methods, &block)
    end

    def around *methods, &block
      @advices << create_advice(Aspector::AdviceMetadata::AROUND, self, methods, &block)
    end

    def target code
      logic = DeferredLogic.new(code)
      @deferred_logics ||= []
      @deferred_logics << logic
      logic
    end

    def to_hash
      {
        "type" => self.class.name,
        "options" => @options,
        "advices" => @advices.map {|advice| advice.to_s }
      }
    end

    private

    def create_advice meta_data, klass_or_module, *methods, &block
      methods.flatten!

      options = meta_data.default_options.clone
      options.merge!(methods.pop) if methods.last.is_a? Hash
      options.merge!(meta_data.mandatory_options)

      # Convert symbols to strings to avoid inconsistencies
      methods.size.times do |i|
        methods[i] = methods[i].to_s if methods[i].is_a? Symbol
      end

      with_method = methods.pop unless block_given?

      Aspector::Advice.new(self,
                           meta_data.advice_type,
                           Aspector::MethodMatcher.new(*methods),
                           with_method,
                           options,
                           &block)
    end
  end
end

