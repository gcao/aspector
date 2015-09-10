require File.expand_path(File.dirname(__FILE__) + '/benchmark_helper')

# Class to which we will bind with aspect
class Klass
  aspector do
    before :test, :before_test
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
