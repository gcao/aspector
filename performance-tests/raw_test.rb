require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class RawTest < Test::Unit::TestCase
  include RubyProf::Test

  class Klass

    aspector do

      raw :test do |method, aspect|
        eval <<-CODE
        alias #{method}_without_aspect #{method}

        define_method :#{method} do
          return #{method}_without_aspect if aspect.disabled?
          before_#{method}
          #{method}_without_aspect
        end
        CODE
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

