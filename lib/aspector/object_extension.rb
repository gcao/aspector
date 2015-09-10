module Aspector
  # Extensions that must be included into the Object class
  module ObjectExtension
    private

    # Direct aspect biding for multiple (optionally) classes
    # @param args multiple classes to which we want to bind and as a last parameter optional
    #   options for aspect
    # @param [Proc] block with the aspect code
    # @return [Aspector::Base] aspector base anonymous descendant class
    # @note You can also access the class body with target block as
    #   presented in one of the examples
    # @note Internally it uses the Aspector method from this module
    # @note It will create a single aspect class that will be applied to all the classes
    # @example Bind aspector to TestClass and DummyClass on a :run method
    #   aspector(TestClass, DummyClass) do
    #     before :run do
    #       puts "This is it!"
    #     end
    #   end
    #
    # @example Bind aspector and add an extra method to the classes by using target block
    #   aspector(TestClass, DummyClass) do
    #     target do
    #       def :run
    #       end
    #     end
    #
    #     before :run do
    #       puts "This is it!"
    #     end
    #   end
    #
    def aspector(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}

      aspect = Aspector(options, &block)

      aspect.apply(self) if self.is_a? Module
      args.each { |target| aspect.apply(target) }

      aspect
    end

    # Method that "imitates" a class like behaviour for building aspects
    # Pretty usefull when we want to define aspects that will be applied to multiple targets
    # @see /examples/aspector_apply_example.rb
    # @param [Hash] hash with additional options for the aspect (if any)
    # @param [Proc] block with the aspect code
    # @return [Aspector::Base] aspector base anonymous descendant class
    # @note You can also access the class body with target block as
    #   presented in one of the examples for aspector method
    # @example Create an aspect that can be attached
    #   aspect = Aspector(class_methods: true) do
    #     before :test do
    #       puts "This is it!"
    #     end
    #   end
    #
    #  aspect.apply(AspectedClass)
    #  AspectedClass.test #=> aspect will be invoked here
    def Aspector(options = {}, &block)
      klass = Class.new(Aspector::Base)
      klass.class_eval { default options }
      klass.class_eval(&block) if block_given?
      klass
    end
  end
end

Object.send(:include, Aspector::ObjectExtension)
