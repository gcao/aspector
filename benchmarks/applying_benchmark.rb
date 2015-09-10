require File.expand_path(File.dirname(__FILE__) + '/benchmark_helper')

ITERATIONS = 10

# Class to which we will bind with aspect
class Klass
  def test(input)
    input.upcase!
  end
end

# Around aspect for benchmarking
class AroundAspect < Aspector::Base
  around :test do |proxy, *args, &block|
    begin
      proxy.call(*args, &block)
    rescue
      nil
    end
  end
end

benchmark 'Around advice good' do
  AroundAspect.apply(Klass)
end
