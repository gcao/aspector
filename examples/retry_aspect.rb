class A

  def test
    puts 'test'
    raise
  end

end

##############################

require_relative '../lib/aspector'

class RetryAspect < Aspector::Base

  module ToBeIncluded
    def retry_this proxy, &block
      proxy.call &block
    rescue => e
      @retry_count ||= 3
      @retry_count -= 1

      @retry_count = nil or raise if @retry_count == 0

      retry
    end
  end

  around :retry_this

end

##############################

RetryAspect.apply A, :method => "test"

a = A.new
a.test

