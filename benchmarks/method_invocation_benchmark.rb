require File.expand_path(File.dirname(__FILE__) + '/benchmark_helper')

# Class with method invokation
class Klass
  def do_something; end

  def test
    do_something
  end

  do_something_method = instance_method(:do_something)

  define_method :test_with_method_object do
    do_something_method.bind(self).call
  end
end

instance = Klass.new

benchmark 'instance.test' do
  instance.test
end

benchmark 'instance.test_with_method_object' do
  instance.test_with_method_object
end
