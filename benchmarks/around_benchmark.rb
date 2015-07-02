require File.expand_path(File.dirname(__FILE__) + '/benchmark_helper')

# Class to which we will bind with aspect
class Klass
  aspector do
    around :test, :around_test
  end

  def test_no_aspect; end

  def test; end

  def around_test(proxy, &block)
    proxy.call(&block)
  end
end

AroundAspect.apply(Klass)

instance = Klass.new

RubyProf.start
ITERATIONS.times { instance.test('good') }
result = RubyProf.stop

print_result(result, 'Around good')

RubyProf.start
ITERATIONS.times { instance.test(nil) }
result = RubyProf.stop

print_result(result, 'Around bad')
