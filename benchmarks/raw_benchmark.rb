require File.expand_path(File.dirname(__FILE__) + '/benchmark_helper')

# Class to which we will bind with aspect
class Klass
  aspector do
    raw :test do |method, _aspect|
      # rubocop:disable Eval
      eval <<-CODE
      alias #{method}_without_aspect #{method}

      define_method :#{method} do
        return #{method}_without_aspect if aspect.disabled?
        before_#{method}
        #{method}_without_aspect
      end
      CODE
    end
  end

  def test_no_aspect; end

  def test; end

  def before_test; end
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
