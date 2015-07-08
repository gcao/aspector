$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aspector'

# Example class to which we will apply our aspects
class ExampleClass
  def test(input)
    puts input.upcase
  end
end

# Aspect used to handle exceptions
class ExceptionHandler < Aspector::Base
  target do
    def handle_exception(proxy, *args, &block)
      proxy.call(*args, &block)
    rescue => e
      puts "Rescued: #{e}"
    end
  end

  around :handle_exception
end

ExceptionHandler.apply(ExampleClass, method: :test)

a = ExampleClass.new
a.test('good')
a.test(nil)
