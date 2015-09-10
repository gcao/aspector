module Aspector
  # Refinements that are used inside Aspector
  module Refinements
    # Class refinements used inside Aspector
    # They allow us to check what type of instance method (public, protected, private) it is
    module Class
      refine ::Class do
        # @param [String, Symbol] method_name that we want to check
        # @return [Boolean] true if there's a method with provided method_name and this
        #   method is private. Otherwise false
        # @example Check if a given instance method is private
        #   DummyClass.instance_method_private?(:run) #=> true
        def instance_method_private?(method_name)
          private_instance_methods.include?(method_name.to_sym)
        end

        # @param [String, Symbol] method_name that we want to check
        # @return [Boolean] true if there's a method with provided method_name and this
        #   method is protected. Otherwise false
        # @example Check if a given instance method is protected
        #   DummyClass.instance_method_protected?(:run) #=> true
        def instance_method_protected?(method_name)
          protected_instance_methods.include?(method_name.to_sym)
        end

        # @param [String, Symbol] method_name that we want to check
        # @return [Boolean] true if there's a method with provided method_name and this
        #   method is public. Otherwise false
        # @example Check if a given instance method is public
        #   DummyClass.instance_method_public?(:run) #=> true
        def instance_method_public?(method_name)
          public_instance_methods.include?(method_name.to_sym)
        end

        # @param [String, Symbol] method_name that we want to check
        # @return [Symbol] what type of method it is (private, protected, public)
        # @note If this method is non of types we assume that it is public, so method_missing
        #   will work without any issues (or any other Ruby magic)
        # @example Get a given instance method type
        #   DummyClass.instance_method_type(:run) #=> :protected
        #   DummyClass.instance_method_type(:run_now) #=> :private
        #   DummyClass.instance_method_type(:run_scheduled) #=> :public
        def instance_method_type(method_name)
          return :private   if instance_method_private?(method_name)
          return :protected if instance_method_protected?(method_name)
          return :public    if instance_method_public?(method_name)

          :public
        end
      end
    end
  end
end
