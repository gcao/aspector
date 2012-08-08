module Aspector
  module DesignByContract
    def self.included target
      target.extend ClassMethods
    end

    module ClassMethods
      def precond *methods, &block
        @preconditions ||= []
        @preconditions << methods if methods.length > 0
        @preconditions << block if block_given?
      end

      def postcond
      end

      def invariant
      end

      def method_added method
        aop_applied_flag = "@dbc_applied_#{method}"
        aop_applied_flag.gsub! %r([?!=+\-\*/\^\|&\[\]<>%~]), "_"
        return if instance_variable_get(aop_applied_flag)

        instance_variable_set(aop_applied_flag, true)

        m = instance_method(method)
        preconditions = @preconditions
        define_method method do |*args, &block|
          if preconditions
            preconditions.flatten.each do |logic|
              if logic.is_a? Proc
                instance_exec *args, &logic
              else
                send logic, *args, &block
              end
            end
          end
          m.bind(self).call(*args, &block)
        end
      ensure
        remove_instance_variable aop_applied_flag if instance_variable_defined? aop_applied_flag
      end
    end

    class AssertionFailure < Exception
      attr :message, :stack_trace

      def initialize message, stack_trace
        @message     = message
        @stack_trace = stack_trace
      end
    end

    module Assert
      def assert bool, message = 'Assertion failure'
        unless bool
          raise AssertionFailure.new(message, caller) if ENV["DBC_RAISE_ON_FAILURE"] == "true"

          $stderr.puts message
          $stderr.puts caller
        end
      end
    end

  end
end

