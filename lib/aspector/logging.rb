module Aspector
  # Class used as a wrapper to get logging instances
  module Logging
    class << self
      def get_logger(context)
        (deconstantize(ENV['ASPECTOR_LOGGER'] || 'Aspector::Logger')).new(context)
      end

      private

      def deconstantize(klass_name)
        Object.const_get(klass_name.to_s)
      rescue NameError
        $stderr.puts "#{klass_name} is not a valid constant name!"
        Aspector::Logger
      end
    end
  end
end
