class A

  def test input
    input.upcase
  end

end

##############################

require_relative '../lib/aspector'

class LoggingAspect < Aspector::Base

  ALL_METHODS = /.*/

  around ALL_METHODS, :except => :class, :method_arg => true do |method, proxy, *args, &block|
    class_method = "#{self.class}.#{method}"
    puts "Entering #{class_method}: #{args.join(',')}"
    result = proxy.call *args, &block
    puts "Exiting  #{class_method}: #{result}"
    result
  end

end

##############################

LoggingAspect.apply(A)
puts "LoggingAspect is applied"

a = A.new
a.test 'input'

LoggingAspect.disable
puts "LoggingAspect is disabled"
a.test 'input'

LoggingAspect.enable
puts "LoggingAspect is enabled"
a.test 'input'

