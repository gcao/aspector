require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Before advices" do
  it "should work" do
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

    aspector(klass) do
      before :test, :do_this
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this test"
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
      before(:test){ value << 'do_block' }
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"do_block test"
  end

  it "new methods should work" do
    klass = Class.new do
      aspector do
        before :test, :do_this
      end

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

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this test"
  end

end
