require File.expand_path(File.dirname(__FILE__) + '/benchmark_helper')

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

AroundAspect.apply(Klass)

instance = Klass.new

benchmark 'Around advice good' do
  instance.test('good')
end

benchmark 'Around advice bad' do
  instance.test(nil)
end
