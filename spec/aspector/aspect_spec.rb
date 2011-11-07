require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Aspector::Aspect" do
  it "#apply" do
    klass = Class.new do
      def value
        @value ||= []
      end

      def test
        value << "test"
      end

      def do_this
        value << "do_this"
      end
    end

    aspect = Aspector do
      before :test, :do_this
    end

    aspect.apply(klass)

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this test"
  end
end
