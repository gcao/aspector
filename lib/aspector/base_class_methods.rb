module Aspector
  class Base
    module ClassMethods
      ::Aspector::Base.extend(self)

      def enable; @disabled = nil; end
      def disable; @disabled = true; end
      def disabled?; @disabled; end

      def aop_advices
        @aop_advices ||= []
      end
      alias :advices :aop_advices

      def aop_default_options
        @aop_default_options ||= {}
      end
      alias :default_options :aop_default_options

      def aop_apply target, options = {}
        aspect_instance = new(target, options)
        aspect_instance.send :aop_apply
        aspect_instance.send :aop_add_method_hooks
        aspect_instance
      end
      alias :apply :aop_apply

      def aop_default options
        if @aop_default_options
          @aop_default_options.merge! options
        else
          @aop_default_options = options
        end
      end
      alias :default :aop_default

      def aop_before *methods, &block
        aop_advices << aop_create_advice(Aspector::AdviceMetadata::BEFORE, self, methods, &block)
      end
      alias :before :aop_before

      def aop_before_filter *methods, &block
        aop_advices << aop_create_advice(Aspector::AdviceMetadata::BEFORE_FILTER, self, methods, &block)
      end
      alias :before_filter :aop_before_filter

      def aop_after *methods, &block
        aop_advices << aop_create_advice(Aspector::AdviceMetadata::AFTER, self, methods, &block)
      end
      alias :after :aop_after

      def aop_around *methods, &block
        aop_advices << aop_create_advice(Aspector::AdviceMetadata::AROUND, self, methods, &block)
      end
      alias :around :aop_around

      def aop_target code = nil, &block
        logic = DeferredLogic.new(code || block)
        aop_deferred_logics << logic
        logic
      end
      alias :target :aop_target

      def aop_options
        DeferredOption.new
      end
      alias :options :aop_options

      private

      def aop_deferred_logics
        @aop_deferred_logics ||= []
      end

      def aop_create_advice meta_data, klass_or_module, *methods, &block
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

