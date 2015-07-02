$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aspector'

# Example class to which we will apply our aspects
class ExampleClass
  def test
    puts 'test'
    fail
  end
end

# Aspect that will be used as a retry with counting
class RetryAspect < Aspector::Base
  target do
    def retry_this(proxy, &block)
      proxy.call(&block)
    rescue
      @retry_count ||= 3
      @retry_count -= 1

      if @retry_count == 0
        @retry_count = nil
        raise
      end

      retry
    end
  end

  around :retry_this
end

RetryAspect.apply(ExampleClass, method: :test)

instance = ExampleClass.new

begin
  instance.test
rescue
  puts 'Fails after 3 retries'
end
