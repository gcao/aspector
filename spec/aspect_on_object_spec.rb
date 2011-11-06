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

      def do_after result
        value << "do_after"
        result
      end

      def do_around &block
        value << "do_around_before"
        result = block.call
        value << "do_around_after"
        result
      end
    end

    obj = klass.new

    eigen_aspector(obj) do
      before :test, :do_before
      after  :test, :do_after
      around :test, :do_around
    end

    obj.test
    obj.value.should == %w"do_around_before do_before test do_after do_around_after"

    obj2 = klass.new
    obj2.test
    obj2.value.should == %w"test"
  end
end
