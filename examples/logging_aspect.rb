class A

  def test input
    input.upcase
  end

end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class LoggingAspect < Aspector::Base

  around /.*/, :except => [:class], :context_arg => true do |context, *args, &block|
    class_method = "#{self.class}.#{context.method_name}"
    puts "Entering #{class_method}: #{args.join(',')}"
    result = block.call *args
    puts "Exiting  #{class_method}: #{result}"
    result
  end

end

LoggingAspect.apply(A)

##############################

a = A.new
a.test 'input'

