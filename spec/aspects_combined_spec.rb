require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Aspects combined" do
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

    aspector(klass) do
      before :test, :do_before
      after  :test, :do_after
      around :test, :do_around
    end

    klass.class_eval do
      aspector do
        before(:test) { value << "do_before_block" }
      end

      def self.method_added method
        method_added_aspector(method)
      end

      def test
        value << "new_test"
      end
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"do_before_block do_around_before do_before new_test do_after do_around_after"
  end
end
