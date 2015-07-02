$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aspector'

# Aspect used to provide process logging
class ProcessLogging < Aspector::Base
  after :spawn do |return_value, *args|
    $stderr.puts args[0].inspect
    return_value
  end
end

ProcessLogging.apply(Process, class_methods: true)
Process.spawn('pwd')
