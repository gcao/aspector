module Aspector
  class Logging
    # Log levels
    ERROR = 50
    WARN  = 40
    INFO  = 30
    DEBUG = 20
    TRACE = 10

    DEFAULT_VISIBLE_LEVEL = INFO

    def self.get_logger context
      if logger_class_name = ENV["ASPECTOR_LOGGER"]
        begin
          unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)+)\z/ =~ logger_class_name
            raise NameError, "#{logger_class_name} is not a valid constant name!"
          end

          logger_class = Object.module_eval("::#{$1}", __FILE__, __LINE__)
          logger_class.new(context)
        rescue => e
          $stderr.puts e.message

          Logger.new(context)
        end
      else
        Logger.new(context)
      end
    end
  end
end
