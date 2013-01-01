module Aspector
  class Base
    module ClassMethods
      ::Aspector::Base.extend(self)

      def aop_enable
        aop_logger.log Logging::INFO, 'enable-aspect'
        send :define_method, :aop_disabled? do
        end

        nil
      end
      alias enable aop_enable

      def aop_disable
        aop_logger.log Logging::INFO, 'disable-aspect'
        send :define_method, :aop_disabled? do
          true
        end

        nil
      end
      alias disable aop_disable

      # if ENV["ASPECTOR_LOGGER"] is set, use it
      # else try to load logem and use Logem::Logger
      # else use built in logger
      def aop_logger
        @aop_logger ||= Logging.get_logger(self)
      end
      alias logger aop_logger

      def aop_logger= logger
        @aop_logger = logger
      end
      alias logger= aop_logger=

      def aop_advices
        @aop_advices ||= []
      end
      alias advices aop_advices

      def aop_default_options
        @aop_default_options ||= {}
      end
      alias default_options aop_default_options

      def aop_apply target, *rest
        options = rest.last.is_a?(Hash) ? rest.pop : {}

        targets = rest.unshift target
        result = targets.map do |target|
          aop_logger.log Logging::INFO, 'apply', target, options.inspect
          aspect_instance = new(target, options)
          aspect_instance.send :aop_apply
          aspect_instance
        end

        result.size == 1 ? result.first : result
      end
      alias apply aop_apply

      def aop_default options
        if @aop_default_options
          @aop_default_options.merge! options
        else
          @aop_default_options = options
        end
      end
      alias default aop_default

      def aop_before *methods, &block
        aop_advices << advice = aop_create_advice(Aspector::AdviceMetadata::BEFORE, self, methods, &block)
        advice.index = aop_advices.size
        aop_logger.log Logging::INFO, 'define-advice', advice
        advice
      end
      alias before aop_before

      def aop_before_filter *methods, &block
        aop_advices << advice = aop_create_advice(Aspector::AdviceMetadata::BEFORE_FILTER, self, methods, &block)
        advice.index = aop_advices.size
        aop_logger.log Logging::INFO, 'define-advice', advice
        advice
      end
      alias before_filter aop_before_filter

      def aop_after *methods, &block
        aop_advices << advice = aop_create_advice(Aspector::AdviceMetadata::AFTER, self, methods, &block)
        advice.index = aop_advices.size
        aop_logger.log Logging::INFO, 'define-advice', advice
        advice
      end
      alias after aop_after

      def aop_around *methods, &block
        aop_advices << advice = aop_create_advice(Aspector::AdviceMetadata::AROUND, self, methods, &block)
        advice.index = aop_advices.size
        aop_logger.log Logging::INFO, 'define-advice', advice
        advice
      end
      alias around aop_around

      def aop_raw *methods, &block
        aop_advices << advice = aop_create_advice(Aspector::AdviceMetadata::RAW, self, methods, &block)
        advice.index = aop_advices.size
        aop_logger.log Logging::INFO, 'define-advice', advice
        advice
      end
      alias raw aop_raw

      def aop_target code = nil, &block
        raise ArgumentError.new('No code or block is passed.') unless code or block_given?

        logic = DeferredLogic.new(code || block)
        aop_deferred_logics << logic
        logic
      end
      alias target aop_target

      def aop_options
        DeferredOption.new
      end
      alias options aop_options

      private

      def aop_deferred_logics
        @aop_deferred_logics ||= []
      end

      def aop_create_advice meta_data, klass_or_module, *methods, &block
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

        methods << aop_options[:method] << aop_options[:methods] if methods.empty?

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

