require 'erb'

module Aspector
  # Interception acts as a proxy between the Aspector::Base instance and all the elements to
  # which we want to apply to given elements
  # Why don't we apply it directly from the aspect instance? Well if we would do this, it would
  # disallow having different options in the apply() method and all the options would be the same
  # Using the interception in between, we can have different set of options for each target
  # For example we can apply the same aspect for different set of methods for each target, etc
  class Interception
    extend Forwardable
    using Refinements::Class

    def_delegator :aspect, :enabled?

    attr_reader :aspect, :target, :options

    # @param aspect [Aspector::Base] aspector instance that owns this interception
    # @param target [Class, Module] element on which we will apply this interception
    # @param options [Hash] hash with options for this interception
    # @return [Aspector::Interception] interception instance
    def initialize(aspect, target, options)
      @aspect  = aspect
      @target  = target
      @options = options
      @wrapped_methods = {}
    end

    # @return [Array<Aspector::Advice>] advices that should be applied by this inteception
    # @note All advices are defined on an aspect class level
    def advices
      aspect.class.storage.advices
    end

    # @return [Aspector::Logger] logger instance
    def logger
      @logger ||= Logging.build(self)
    end

    # Will apply all the advices to a given target based on provided options
    def apply
      invoke_deferred_logics
      return if advices.empty?

      define_methods_for_advice_blocks
      add_to_instances unless @options[:existing_methods_only]
      apply_to_methods unless @options[:new_methods_only]
      add_method_hooks unless @options[:existing_methods_only]
      # TODO: clear deferred logic results if they are not used in any advice
      self
    end

    # Applies advices to a given method
    # @note This method is public only because we use it from define_method on a module
    # @note If will figure out the method scope (private/public/protected) on its own
    # @param method [Symbol] method to which we want to apply this interception
    def apply_to_method(method)
      filtered_advices = filter_advices advices, method
      return if filtered_advices.empty?

      logger.debug 'apply-to-method', method

      scope ||= context.instance_method_type(method)

      recreate_method method, filtered_advices, scope
    end

    private

    # Defines on a target element new methods that will contain advices logic
    # as long as their blocks. Then we can invoke advices logic as a normal methods
    # In a way it just casts a block to methods for peformance reasons
    # If we have advices that just execute already existing methods, this won't create
    # anything
    # @note All methods like this are set to private - they should stay as an internal
    #   implementation detail
    def define_methods_for_advice_blocks
      advices.each do |advice|
        next if advice.raw?
        next unless advice.advice_block
        context.send :define_method, advice.with_method, advice.advice_block
        context.send :private, advice.with_method
      end
    end

    # context is where advices will be applied (i.e. where methods are modified),
    # can be different from target because when the target is an instance and
    # we want to apply to instance methods, we need to use element singleton_class
    # @return [Class] context on which we will apply advices
    def context
      return @target if @target.is_a?(Module) && !@options[:class_methods]

      @target.singleton_class
    end

    # Will apply all the advices to all methods that match
    def apply_to_methods
      # If method/methods option is set and all are String or Symbol, apply to those only, instead of
      # iterating through all methods
      methods = [@options[:method] || @options[:methods]]
      methods.compact!
      methods.flatten!

      if !methods.empty? && methods.all?{ |method| method.is_a?(String) || method.is_a?(Symbol) }
        methods.each do |method|
          apply_to_method(method.to_s)
        end

        return
      end

      context.public_instance_methods.each do |method|
        apply_to_method(method.to_s)
      end

      context.protected_instance_methods.each do |method|
        apply_to_method(method.to_s)
      end

      if @options[:private_methods]
        context.private_instance_methods.each do |method|
          apply_to_method(method.to_s)
        end
      end
    end

    # @param logic Deferred logic for which we want to get the results
    # @return Deferred logic invokation results
    def deferred_logic_results(logic)
      @deferred_logic_results[logic]
    end

    # @param method [String] method name for which we want to get the original method
    # @return [UnboundMethod] original method that we wrapped around
    def get_wrapped_method_of(method)
      @wrapped_methods[method]
    end

    # Invokes deferred logics blocks on a target element and stores deferred logic
    # invokations results
    def invoke_deferred_logics
      logics = @aspect.class.storage.deferred_logics
      return if logics.empty?

      logics.each do |logic|
        result = logic.apply context, aspect
        if advices.detect { |advice| advice.use_deferred_logic? logic }
          @deferred_logic_results ||= {}
          @deferred_logic_results[logic] = result
        end
      end
    end

    # Saves references to interceptions on a given target (its context) level
    # The reference is stored there only for advices that are not being applied
    # for existing methods only. The storage is used to remember interceptions
    # that should be applied for methods that were defined after the aspect
    # was applied
    def add_to_instances
      # Store only those interceptions that are not marked to be used for existing methods only
      return if options[:existing_methods_only]

      interceptions_storage = context.instance_variable_get(:@interceptions_storage)
      unless interceptions_storage
        interceptions_storage = InterceptionsStorage.new
        context.instance_variable_set(:@interceptions_storage, interceptions_storage)
      end
      interceptions_storage << self
    end

    # Redefines singleton_method_added and method_added methods so they are monitored
    # If new method is added we will apply to it appropriate advices
    def add_method_hooks
      eigen_class = @target.singleton_class

      if @options[:class_methods]
        return unless @target.is_a?(Module)

        orig_singleton_method_added = @target.method(:singleton_method_added)

        eigen_class.send :define_method, :singleton_method_added do |method|
          aspector_singleton_method_added(method)
          orig_singleton_method_added.call(method)
        end
      else
        if @target.is_a? Module
          orig_method_added = @target.method(:method_added)
        else
          orig_method_added = eigen_class.method(:method_added)
        end

        eigen_class.send :define_method, :method_added do |method|
          aspector_instance_method_added(method)
          orig_method_added.call(method)
        end
      end
    end

    # Picks only advices that should be applied on a given method
    # @param advices [Array<Aspector::Advice>] all the advices that we want to filter
    # @param method [String] method name for which we want to pick proper advices
    # @return [Array<Aspector::Advice>] advices that match given method
    def filter_advices(advices, method)
      advices.select do |advice|
        advice.match?(method, self)
      end
    end

    # Recreates a given method applying all the advices one by one
    # @param method [String] method name of a method that we want to recreate
    # @param advices [Array<Aspector::Advice>] all the advices that
    #   should be applied (after filtering)
    # @param scope [Symbol] method visibility (private, protected, public)
    def recreate_method(method, advices, scope)
      context.instance_variable_set(:@aspector_creating_method, true)

      raw_advices = advices.select(&:raw?)

      if raw_advices.size > 0
        raw_advices.each do |advice|
          if @target.is_a?(Module) && !@options[:class_methods]
            @target.class_exec method, self, &advice.advice_block
          else
            @target.instance_exec method, self, &advice.advice_block
          end
        end

        return if raw_advices.size == advices.size
      end

      begin
        @wrapped_methods[method] = context.instance_method(method)
      rescue
        # ignore undefined method error
        if @options[:existing_methods_only]
          logger.log Logging::WARN, 'method-not-found', method
        end

        return
      end

      before_advices = advices.select(&:before?) + advices.select(&:before_filter?)
      after_advices  = advices.select(&:after?)
      around_advices = advices.select(&:around?)

      (around_advices.size - 1).downto(1) do |i|
        advice = around_advices[i]
        recreate_method_with_advices method, [], [], advice
      end

      recreate_method_with_advices(
        method,
        before_advices,
        after_advices,
        around_advices.first
      )

      context.send scope, method if scope != :public
    ensure
      context.send :remove_instance_variable, :@aspector_creating_method
    end

    # Recreates method with given advices. It applies the MethodTemplate::TEMPLATE
    # @param method [String] method name of a method that we want to recreate
    # @param before_advices [Array<Aspector::Advice>] before advices that should be applied
    # @param after_advices [Array<Aspector::Advice>] after advices that should be applied
    # @param around_advice [Aspector::Advice] single around advice
    # @note We can recreate method only with single around advice at once - so we loop if we have
    #   more than a single around advice
    def recreate_method_with_advices(
      method,
      before_advices,
      after_advices,
      around_advice
    )
      aspect = @aspect
      logger = @logger
      interception = self
      orig_method = get_wrapped_method_of method

      code = MethodTemplate::TEMPLATE.result(binding)
      logger.debug 'generate-code', method, code
      context.class_eval code, __FILE__, __LINE__ + 4
    end
  end
end
