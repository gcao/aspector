require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Aspector" do
  it "should work" do
    klass = Class.new do
      attr :value

      def initialize
        @value = []
      end

      def test
        @value << "test"
      end

      def do_this
        @value << "do_this"
      end

      def do_that result
        @value << "do_that"
        result
      end
    end

    aspector(klass) do
      before :test, :do_this
      after  :test, :do_that
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this test do_that"
  end
end
