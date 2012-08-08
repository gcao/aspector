module Aspector
  module DesignByContract
    def self.included target
      target.extend ClassMethods
    end

    module ClassMethods
      def precond &block
        @preconditions ||= []
        @preconditions << block
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
            preconditions.each do |block|
              instance_exec *args, &block
            end
          end
          m.bind(self).call(*args, &block)
        end
      ensure
        remove_instance_variable aop_applied_flag if instance_variable_defined? aop_applied_flag
      end
    end

    module Assert
      def assert bool, message = 'Assertion failure'
        unless bool
          $stderr.puts message
          $stderr.puts caller
        end
      end
    end

  end
end

