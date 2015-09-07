module Aspector
  # Class used as a wrapper to get logging instances
  # It provides logger detection (from ENV) and creates a logger instance with a proper context
  module Logging
    class << self
      # @param context [Aspector::Base, Class] context in which we want to log information
      # @note it will log more details if it is an Aspector internal context
      # @return [Aspector::Logger, Logger] aspector logger that logs in a given context
      #   or provided logger
      # @example Create a logger instance inside Aspector::Base
      #   @logger ||= Aspector::Logging.get_logger(self)
      def get_logger(context)
        (deconstantize(ENV['ASPECTOR_LOGGER'] || 'Aspector::Logger')).new(context)
      end

      private

      # @param [String, Symbol] stringified class/module name that we want to convert
      #   to a real working class/module instance
      # @return [Class] class/module that was fetched from its string version
      # @note If it cannot detect a valid class based on the name,
      #   it will return an Aspector::Logger instance as a fallback
      # @example Get a class DummyClass based on its 'DummyClass' string
      #   deconstantize('DummyClass') #=> 'DummyClass'
      # @example Get a namespaced class reference
      #   deconstantize('Users::UserRole') #=> User::UserRole
      # @example Try to get class that doesn't exist
      #   deconstantize('NonExistingClass') #=> Aspector::Logger
      def deconstantize(klass_name)
        Object.const_get(klass_name.to_s)
      rescue NameError
        $stderr.puts "#{klass_name} is not a valid constant name!"
        Aspector::Logger
      end
    end
  end
end
