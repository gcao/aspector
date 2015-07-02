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

RubyProf.start
ITERATIONS.times { instance.test('good') }
result = RubyProf.stop

print_result(result, 'Around advice good')

RubyProf.start
ITERATIONS.times { instance.test(nil) }
result = RubyProf.stop

print_result(result, 'Around advice bad')
