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

benchmark 'instance.test_no_aspect' do
  instance.test_no_aspect
end

benchmark 'instance.test' do
  instance.test
end
