require File.expand_path(File.dirname(__FILE__) + '/benchmark_helper')

# Example class that we use with aspector
class Klass
  aspector do
    after :test, :after_test
  end

  def test_no_aspect; end

  def test; end

  def after_test(_result); end
end

instance = Klass.new

RubyProf.start
ITERATIONS.times { instance.test_no_aspect }
result = RubyProf.stop

print_result(result, 'instance.test_no_aspect')

RubyProf.start
ITERATIONS.times { instance.test }
result = RubyProf.stop

print_result(result, 'instance.test')
