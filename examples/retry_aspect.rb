class A

  def test
    puts 'test'
    raise
  end

end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class RetryAspect < Aspector::Base

  target do
    def retry_this &block
      block.call
    rescue => e
      @retry_count ||= 3
      @retry_count -= 1

      @retry_count = nil or raise if @retry_count == 0

      retry
    end
  end

  around :test, :retry_this

end

RetryAspect.apply(A)

##############################

a = A.new
a.test

