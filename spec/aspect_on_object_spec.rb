require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Aspector for object" do
  it "should work" do
    klass = Class.new do
      def value
        @value ||= []
      end

      def test
        value << "test"
      end

      def do_before
        value << "do_before"
      end
    end

    obj = klass.new

    aspector(obj) do
      before :test, :do_before
    end

    obj.test
    obj.value.should == %w"do_before test"

    obj2 = klass.new
    obj2.test
    obj2.value.should == %w"test"
  end
end
