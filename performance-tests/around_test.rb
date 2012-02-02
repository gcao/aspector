require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class AroundTest < Test::Unit::TestCase
  include RubyProf::Test

  class Klass

    aspector do
      around :test, :around_test
    end

    def test_no_aspect; end

    def test; end

    def around_test &block
      block.call
    end
  end

  def test_around
    o = Klass.new
    o.test_no_aspect
    o.test
  end
end

