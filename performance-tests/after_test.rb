require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class AfterTest < Test::Unit::TestCase
  include RubyProf::Test

  class Klass

    aspector do
      after :test, :after_test
    end

    def test_no_aspect; end

    def test; end

    def after_test result; end
  end

  def test_after
    o = Klass.new
    o.test_no_aspect
    o.test
  end
end

