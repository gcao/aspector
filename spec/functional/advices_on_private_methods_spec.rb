require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Advices on private methods" do
  it "should work" do
    klass = Class.new do
      def value
        @value ||= []
      end

      private

      def test
        value << "test"
      end

      def do_before
        value << "do_before"
      end
    end

    aspector(klass, :private_methods => true) do
      before :test, :do_before
    end

    obj = klass.new
    obj.send :test
    obj.value.should == %w"do_before test"
  end
end
