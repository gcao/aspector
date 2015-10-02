module Aspector
  module Extensions
    # Module extensions that we need to make aspector work with methods that will be defined
    # after an aspect instance was binded to a class/module
    module Module
      using Refinements::String

      private

      # Invoked when a new instance method was added to a class/module
      # This will be invoked for instance methods
      # This method triggers applying all the aspects from a given interception
      #   to this newly created method
      # @param [Symbol] method name of a method that was just defined
      def aspector_instance_method_added(method)
        aspector_method_added(self, method)
      end

      # Invoked when a new class method was added to a class/module
      # This will be invoked for class methods
      # This method triggers applying all the aspects from a given interception
      #   to this newly created method
      # @param [Symbol] method name of a method that was just defined
      def aspector_singleton_method_added(method)
        aspector_method_added(singleton_class, method)
      end

      # Triggers applying aspects on a newly created method
      # @param target [Class] class on which the method was defined. Keep in mind that
      #   it might be a normal class for instance methods or a singleton class of a
      #   class when applying on a class level
      # @param method [Symbol] method name of a method that was just defined
      def aspector_method_added(target, method)
        interceptions_storage = target.instance_variable_get(:@interceptions_storage)
        aspector_applied_flag = "aspector_applied_#{method}".to_instance_variable_name!

        return if target.instance_variable_get(:@aspector_creating_method)
        return if interceptions_storage.nil?
        return if interceptions_storage.empty?
        return if target.instance_variable_get(aspector_applied_flag)

        begin
          target.instance_variable_set(aspector_applied_flag, true)
          interceptions_storage.apply_to_method(method.to_s)
        ensure
          target.instance_variable_set(aspector_applied_flag, nil)
        end
      end
    end
  end
end

::Module.send(:include, Aspector::Extensions::Module)
