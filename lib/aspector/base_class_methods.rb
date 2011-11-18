module Aspector
  class Base
    module ClassMethods
      ::Aspector::Base.extend(self)

      def advices
        @advices ||= []
      end

      def options
        @options ||= {}
      end

      def deferred_logics
        @deferred_logics ||= []
      end

      def apply target, options = {}
        instances = target.instance_variable_get(:@aspector_instances)
        return if instances and instances.detect {|instance| instance.is_a?(self) }

        aspect_instance = new(target, options)
        aspect_instance.apply
      end

      def default options
        if @options
          @options.merge! options
        else
          @options = options
        end
      end

      def before *methods, &block
        advices << create_advice(Aspector::AdviceMetadata::BEFORE, self, methods, &block)
      end

      def before_filter *methods, &block
        advices << create_advice(Aspector::AdviceMetadata::BEFORE_FILTER, self, methods, &block)
      end

      def after *methods, &block
        advices << create_advice(Aspector::AdviceMetadata::AFTER, self, methods, &block)
      end

      def around *methods, &block
        advices << create_advice(Aspector::AdviceMetadata::AROUND, self, methods, &block)
      end

      def target code = nil, &block
        logic = DeferredLogic.new(code || block)
        deferred_logics << logic
        logic
      end

      def deferred_option key
        DeferredOption.new(key)
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
end

