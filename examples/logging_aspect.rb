$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aspector'

# Example class to which we will apply our aspects
class ExampleClass
  def test(input)
    input.upcase
  end
end

# Aspect used as a logging hookup
class LoggingAspect < Aspector::Base
  ALL_METHODS = /.*/

  around ALL_METHODS, except: :class, method_arg: true do |method, proxy, *args, &block|
    class_method = "#{self.class}.#{method}"
    puts "Entering #{class_method}: #{args.join(',')}"
    result = proxy.call(*args, &block)
    puts "Exiting  #{class_method}: #{result}"
    result
  end
end

LoggingAspect.apply(ExampleClass)
puts 'LoggingAspect is applied'

instance = ExampleClass.new
instance.test 'input'

LoggingAspect.disable
puts 'LoggingAspect is disabled'
instance.test 'input'

LoggingAspect.enable
puts 'LoggingAspect is enabled'
instance.test 'input'
