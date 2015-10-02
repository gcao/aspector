module Aspector
  class Base
    # Methods that allow us to work with aspects (define them, etc)
    # They are included in the Base class but we removed them for visibility reasons
    # @note They are marked as private because we use them only inside of the
    #   aspect that we want to define. This is a real "interface" for the programmers
    #   that want to use this gem - everything else is private
    module Dsl
      private

      Aspector::Advice::TYPES.each do |type_name|
        # Defines methods that allow us to build aspects
        # @param methods_and_options All the arguments that we want to pass. It should contain
        #   all the methods names (or regexp matches) for which we want to apply our aspect and
        #   optional (not required) options that we want to provide to the aspect.
        #   So: first we have to provide methods and regexps for which we want to apply aspect
        #   the we can provide and optional hash arguments with any option that we want
        #   We might also skip the methods definitions but then we need to provide them when we
        #   apply a given aspect
        # @note If no block givem it will use the last method name provided as an invokation
        #   method that will be executed then aspect is applied
        #
        # @example Simple example for before
        #   before :run do
        #     puts 'Executing a before action!'
        #   end
        #
        # @example before example with a method that will be executed. The :before_run will
        #   be executed before the run execution. However if we would provide a block, then
        #   the block would be evaluated for both methods
        #
        #   before :run, :before_run
        #
        # @example Define aspect only with additional options (without method names that we will
        #   provide when we will apply the aspect)
        #
        #  after timeout: 10, connection_pool: 20 do
        #  end
        define_method type_name do |*methods_and_options, &block|
          advice = Aspector::Advice::Builder.new(type_name, methods_and_options, &block).build
          storage.advices << advice
          advice
        end

        private type_name
      end

      # Allows to set default options for a given aspect
      # @param options [Hash] hash with default options for this aspect
      # @note We can also pass options that are not specifically aspect settings but general
      #   options that we will want to use in the aspected code (see the examples below)
      #
      # @example Create an aspect with default options
      #   class EmptyAspect < Aspector::Base
      #     default private_methods: true
      #   end
      #
      # @example Create an aspect with default options used by aspector and some extra parameters
      #   that we want to use inside code (options that does not influence the aspector behaviour)
      #
      #   class ExampleAspect < Aspector::Base
      #     default private_methods: true, super_option: 60, key_option: 2
      #
      #     before :run, interception_arg: true do |interception|
      #       print "#{interception.options[:super_option]}\n"
      #       print "#{interception.options[:key_option]}\n"
      #     end
      #   end
      def default(options)
        storage.default_options.merge!(options)
      end

      # Allows us to define code that will be applied to the target class/module/instance
      # together with an aspect
      # @note When we define a new target, it will store built deferred logic into
      #   this class storage deferred logics array
      # @param code [Proc] code that we want to apply to a target class
      # @param block [Proc] block with code if we want to declare it directly
      # @raise [Aspector::Errors::CodeBlockRequired] raised when we require a block
      #   of code, but none provided
      # @example Define aspect with a target method that will be applied on a ExampleClass
      #   class ExampleAspect < Aspector::Base
      #     target do
      #       def run!
      #         puts 'Running!'
      #       end
      #     end
      #   end
      #
      #   class ExampleClass
      #   end
      #
      #   ExampleAspect.apply(ExampleClass)
      #   ExampleClass.new.run! #=> 'Running!'
      #
      # @example Define target with a variable that contains code that should be executed on a
      #   target class/module/instance
      #   class ExampleAspect < Aspector::Base
      #     action = Proc.new do
      #       def run!
      #         puts 'Running!'
      #       end
      #     end
      #
      #     target action
      #   end
      #
      #   class ExampleClass
      #   end
      #
      #   ExampleAspect.apply(ExampleClass)
      #   ExampleClass.new.run!
      def target(code = nil, &block)
        fail Errors::CodeBlockRequired unless code || block_given?

        logic = Deferred::Logic.new(code || block)
        # Since it is deferred, we need to store it for future use
        storage.deferred_logics << logic
        logic
      end
    end
  end
end
