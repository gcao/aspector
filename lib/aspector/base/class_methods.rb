module Aspector
  class Base
    # Class methods for Aspector::Base
    module ClassMethods
      extend Forwardable

      # Invokations of those methods should be delegated to #storage object
      %i(
        logger status
      ).each do |method|
        def_delegator :storage, method
      end

      # Invokations of those methods should be delegated to #status object
      %i(
        disable! enable! enabled?
      ).each do |method|
        def_delegator :status, method
      end

      # @return [Advice::Base::Storage] storage instance for this class
      # @example Get logger from storage
      #   storage.logger #=> logger instance
      def storage
        @storage ||= Storage.new(self)
      end

      # Applies this aspect to provided class/method/instance
      # @param target [Class] target class/method/instance to which we want to apply this aspect
      # @param rest Optional arguments that might contain more elements to which we want to
      #   apply the aspect and/or options
      # @example Apply to a single class without additional things
      #   apply(SingleClass)
      # @example Apply to a single module with additional options
      #   apply(SingleModule, option_key: 1234)
      # @example Apply at once to module and class with additional options
      #   apply(SingleClass, SingleModule, option_attribute: true)
      def apply(target, *rest)
        options = rest.last.is_a?(Hash) ? rest.pop : {}

        targets = rest.unshift target
        targets.map do |apply_target|
          logger.info 'apply', apply_target, options.inspect
          instance = new
          instance.send :apply, apply_target, options
        end
      end
    end
  end
end
