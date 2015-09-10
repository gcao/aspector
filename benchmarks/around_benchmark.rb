require File.expand_path(File.dirname(__FILE__) + '/benchmark_helper')

# Class to which we will bind with aspect
class Klass
  aspector do
    around :test, :around_test
  end

  def test_no_aspect; end

  def test; end

  def around_test(proxy, *_args, &block)
    proxy.call(&block)
  end
end

instance = Klass.new

benchmark 'Around good' do
  instance.test('good')
end

benchmark 'Around bad' do
  instance.test(nil)
end
