require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "After advices" do
  it "should work" do
    klass = Class.new do
      def value
        @value ||= []
      end

      def test
        value << "test"
      end

      def do_this result
        value << "do_this"
        result
      end
    end

    aspector(klass) do
      after :test, :do_this
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"test do_this"
  end

  it "logic in block" do
    klass = Class.new do
      def value
        @value ||= []
      end

      def test
        value << "test"
      end
    end

    aspector(klass) do
      after(:test) do |result|
        value << 'do_block'
        result
      end
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"test do_block"
  end
end
