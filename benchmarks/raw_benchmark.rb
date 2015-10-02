require File.expand_path(File.dirname(__FILE__) + '/benchmark_helper')

# Class to which we will bind with aspect
class Klass
  aspector do
    raw :test do |method, _aspect|
      # rubocop:disable Eval
      eval <<-CODE
      alias #{method}_without_aspect #{method}

      define_method :#{method} do
        return #{method}_without_aspect unless _aspect.enabled?
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

benchmark 'instance.test_no_aspect' do
  instance.test_no_aspect
end

benchmark 'instance.test' do
  instance.test
end
