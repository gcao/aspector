$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aspector'

# Example that shows how to use Aspector with a single instance
class ExampleClass
  def test
    puts 'test'
  end
end

# Aspect that will be applied on an instance
class InstanceAspect < Aspector::Base
  target do
    def do_this
      puts 'do_this'
    end
  end

  before :test, :do_this

  before :test do
    puts 'do_that'
  end
end

asp_instance = ExampleClass.new
not_instance = ExampleClass.new

InstanceAspect.apply(asp_instance)

asp_instance.test # This instance will have an aspect added
not_instance.test # This instance wont have aspect added
