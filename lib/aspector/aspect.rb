require 'erb'

module Aspector
  class Aspect

    attr_reader :advices, :deferred_logics

    def initialize options = {}, &block
      @options = options
      @advices = []
      instance_eval &block
    end

    def apply target, options = {}
      target = get_target(target)

      aspect_instance = AspectInstance.new(target, self, options)

      @advices.each do |advice|
        next unless advice.advice_block
        target.send :define_method, advice.with_method, advice.advice_block
      end

      aspect_instance.apply_to_methods
   end

    def get_target target
      return target if target.is_a?(Module) and not @options[:eigen_class]

      class << target
        self
      end
    end

    def advices_for_method method, context
      @advices.select do |advice|
        advice.match?(method, context)
      end
    end

    def recreate_method target, method, advices
      grouped_advices = []

      advices.each do |advice|
        if advice.around? and not grouped_advices.empty?
          recreate_method_with_advices target, method, grouped_advices

          grouped_advices = []
        end

        grouped_advices << advice
      end

      # create wrap method for before/after advices which are not wrapped inside around advice.
      recreate_method_with_advices target, method, grouped_advices unless grouped_advices.empty?
    end

    def recreate_method_with_advices target, method, advices
      before_advices = advices.select {|advice| advice.before? or advice.before_filter? }
      after_advices  = advices.select {|advice| advice.after?  }
      around_advice  = advices.first if advices.first.around?

      code = METHOD_TEMPLATE.result(binding)
      #puts code
      # line no is the actual line no of METHOD_TEMPLATE + 5
      target.class_eval code, __FILE__, 12
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
      { "type" => self.class.name,
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

