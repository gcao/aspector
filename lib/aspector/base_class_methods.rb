module Aspector
  class Base
    module ClassMethods
      ::Aspector::Base.extend(self)

      Aspector::Advice::TYPES.each do |type_name|
        define_method type_name do |*methods, &block|
          meta = Object.const_get("Aspector::AdviceMetadata::#{type_name.to_s.upcase}")
          advices << advice = _create_advice_(meta, self, methods, &block)
          advice.index = advices.size
          logger.info 'define-advice', advice
          advice
        end

        private type_name
      end

      def enable
        logger.info 'enable-aspect'

        send :define_method, :disabled? do
          false
        end
      end

      def disable
        logger.info 'disable-aspect'

        send :define_method, :disabled? do
          true
        end
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
        targets.map do |target|
          logger.info 'apply', target, options.inspect
          instance = new
          instance.send :apply, target, options
        end
      end

      private

      def default options
        @default_options ||= {}
        @default_options.merge!(options)
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

