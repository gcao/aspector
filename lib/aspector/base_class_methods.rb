module Aspector
  class Base
    module ClassMethods
      ::Aspector::Base.extend(self)

      def enable
        logger.log Logging::INFO, 'enable-aspect'
        send :define_method, :disabled? do
        end

        nil
      end

      def disable
        logger.log Logging::INFO, 'disable-aspect'
        send :define_method, :disabled? do
          true
        end

        nil
      end

      # if ENV["ASPECTOR_LOGGER"] is set, use it
      # else try to load logem and use Logem::Logger
      # else use built in logger
      def logger
        @logger ||= Logging.get_logger(self)
      end

      def advices
        @advices ||= []
      end

      def default_options
        @default_options ||= {}
      end

      def apply target, *rest
        options = rest.last.is_a?(Hash) ? rest.pop : {}

        targets = rest.unshift target
        result = targets.map do |target|
          logger.log Logging::INFO, 'apply', target, options.inspect
          aspect_instance = new(target, options)
          aspect_instance.send :apply
          aspect_instance
        end

        result.size == 1 ? result.first : result
      end
      
      private

      def default options
        if @default_options
          @default_options.merge! options
        else
          @default_options = options
        end
      end

      def before *methods, &block
        advices << advice = _create_advice_(Aspector::AdviceMetadata::BEFORE, self, methods, &block)
        advice.index = advices.size
        logger.log Logging::INFO, 'define-advice', advice
        advice
      end

      def before_filter *methods, &block
        advices << advice = _create_advice_(Aspector::AdviceMetadata::BEFORE_FILTER, self, methods, &block)
        advice.index = advices.size
        logger.log Logging::INFO, 'define-advice', advice
        advice
      end

      def after *methods, &block
        advices << advice = _create_advice_(Aspector::AdviceMetadata::AFTER, self, methods, &block)
        advice.index = advices.size
        logger.log Logging::INFO, 'define-advice', advice
        advice
      end

      def around *methods, &block
        advices << advice = _create_advice_(Aspector::AdviceMetadata::AROUND, self, methods, &block)
        advice.index = advices.size
        logger.log Logging::INFO, 'define-advice', advice
        advice
      end

      def raw *methods, &block
        advices << advice = _create_advice_(Aspector::AdviceMetadata::RAW, self, methods, &block)
        advice.index = advices.size
        logger.log Logging::INFO, 'define-advice', advice
        advice
      end

      def target code = nil, &block
        raise ArgumentError.new('No code or block is passed.') unless code or block_given?

        logic = DeferredLogic.new(code || block)
        _deferred_logics_ << logic
        logic
      end

      def options
        DeferredOption.new
      end

      def _deferred_logics_
        @deferred_logics ||= []
      end

      def _create_advice_ meta_data, klass_or_module, *methods, &block
        methods.flatten!

        options = meta_data.default_options.clone
        options.merge!(methods.pop) if methods.last.is_a? Hash
        options.merge!(meta_data.mandatory_options)

        if meta_data.advice_type == Aspector::Advice::RAW
          raise "Bad raw advice - code block is required" unless block_given?
          with_method = nil
        else
          with_method = methods.pop unless block_given?
        end

        # Convert symbols to strings to avoid inconsistencies
        methods.size.times do |i|
          methods[i] = methods[i].to_s if methods[i].is_a? Symbol
        end

        methods << DeferredOption.new(:method) << DeferredOption.new(:methods) if methods.empty?

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

