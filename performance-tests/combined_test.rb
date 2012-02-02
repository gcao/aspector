require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class CombinedTest < Test::Unit::TestCase
  include RubyProf::Test

  class Test

    aspector do
      before :test, :before_test
      after  :test, :after_test
      around :test, :around_test
    end

    def test_no_aspect; end

    def test; end

    def before_test; end

    def after_test result; end

    def around_test &block
      block.call
    end
  end

  def test_combined
    o = Test.new
    o.test_no_aspect
    o.test
  end
end

