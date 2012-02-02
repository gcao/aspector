require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class MethodInvokationTest < Test::Unit::TestCase
  include RubyProf::Test

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

  def test_method_invocation
    o = Klass.new
    o.test
    o.test_with_method_object
  end
end
