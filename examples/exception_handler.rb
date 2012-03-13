class A

  def test input
    puts input.upcase
  end

end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class ExceptionHandler < Aspector::Base

  target do
    def handle_exception *args, &proxy
      proxy.call
    rescue => e
      puts "Rescued: #{e}"
    end
  end

  around options[:method], :handle_exception

end

##############################

ExceptionHandler.apply(A, :method => :test)

a = A.new
a.test 'good'
a.test nil

