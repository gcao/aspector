module Aspector
  # Module containing elements that are dereffered
  module Deferred
    # Object that is used to store and apply deferred logic
    # This is used to apply logic defined in the aspect directly to a target class
    # by using the "target" method.
    # That way we can add an extra logic (methods and other elements) to a target class
    # directly from an aspect itself
    #
    # @example This example will shows how the whole deferred logic works
    #   target do
    #     def run
    #       puts 'Running!'
    #     end
    #   end
    #
    #   DummyClass.new.run #=> 'Running!'
    #
    # @example Creating deferred logic and applying it to a target class/module
    #   code = lambda do
    #     def run
    #       puts 'Running!'
    #     end
    #   end
    #
    #   logic = Aspector::Deferred::Logic.new(code)
    #   DummyClass.new.run #=> undefined method run
    #   logic.apply(DummyClass)
    #   DummyClass.new.run #=> 'Running!'
    class Logic
      # @param code [Proc] block of code that should be evaluated in a target class/module context
      # @raise [Aspector::Deferred::Logic::InvalidCodeClass] raised when we try to use something
      #   else than a Proc as a code
      # @return [Aspector::Deferred::Logic] deferred logic instance that can be used to apply
      #   logic to any class/module
      def initialize(code)
        fail Errors::CodeBlockRequired, code.class unless code.is_a?(Proc)
        @code = code
      end

      # Applies code to a given target class
      # @param target [Class, Module] class or module to which we want to apply code
      # @param args [Array] arguments that should be passed to a block
      #   that we will be evaluating in a target class/module context
      # @example Simple example without additional arguments
      #   logic.code #=> -> { def run; end }
      #   logic.apply(DummyClass)
      #   DummyClass.new.run
      # @example Applying block that has addditional arguments
      #   logic.code #=> -> (attr_name) { attr_accessor attr_name }
      #   logic.apply(DummyClass, :name)
      #   dummy = DummyClass.new
      #   dummy.name = 'Test'
      #   dummy.name #=> 'Test'
      def apply(target, *args)
        target.class_exec(*args, &@code)
      end
    end
  end
end
