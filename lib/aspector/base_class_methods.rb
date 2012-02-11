module Aspector
  class Base
    module ClassMethods
      ::Aspector::Base.extend(self)

      def apply target, options = {}
        aspect_instance = new(target, options)
        aspect_instance.send :_apply_
        aspect_instance.send :_add_method_hooks_
        aspect_instance
      end

      def default options
        if @default_options
          @default_options.merge! options
        else
          @default_options = options
        end
      end

      def before *methods, &block
        _advices_ << _create_advice_(Aspector::AdviceMetadata::BEFORE, self, methods, &block)
      end

      def before_filter *methods, &block
        _advices_ << _create_advice_(Aspector::AdviceMetadata::BEFORE_FILTER, self, methods, &block)
      end

      def after *methods, &block
        _advices_ << _create_advice_(Aspector::AdviceMetadata::AFTER, self, methods, &block)
      end

      def around *methods, &block
        _advices_ << _create_advice_(Aspector::AdviceMetadata::AROUND, self, methods, &block)
      end

      def target code = nil, &block
        logic = DeferredLogic.new(code || block)
        _deferred_logics_ << logic
        logic
      end

      def options
        DeferredOption.new
      end

      private

      def _advices_
        @advices ||= []
      end

      def _default_options_
        @default_options ||= {}
      end

      def _deferred_logics_
        @deferred_logics ||= []
      end

      def _create_advice_ meta_data, klass_or_module, *methods, &block
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

