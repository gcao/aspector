require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class RawTest < Test::Unit::TestCase
  include RubyProf::Test

  class Klass

    aspector do
      raw :test do |method, aspect|
        alias_method :"#{method}_without_aspect", method
        define_method method do
          before_test
          test_without_aspect
        end
      end
    end

    def test_no_aspect; end

    def test; end

    def before_test; end
  end

  def test_raw
    o = Klass.new
    o.test_no_aspect
    o.test
  end
end

