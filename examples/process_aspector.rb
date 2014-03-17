$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class ProcessLogging < Aspector::Base
  after :spawn do |return_value, *args|
    $stderr.puts args[0].inspect 
  end
end

ProcessLogging.apply Process, :class_methods => true
Process.spawn 'pwd'

