require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class BeforeTest < Test::Unit::TestCase
  include RubyProf::Test

  class Klass

    aspector do
      before :test, :before_test
    end

    def test_no_aspect; end

    def test; end

    def before_test; end
  end

  def test_before
    o = Klass.new
    o.test_no_aspect
    o.test
  end
end

