require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Before advices" do
  it "should work" do
    klass = create_test_class do
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
    klass = create_test_class

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

  it "method_arg" do
    klass = Class.new do
      aspector do
        before :test, :do_this, :method_arg => true
      end

      def value
        @value ||= []
      end

      def test
        value << "test"
      end

      def do_this method
        value << "do_this(#{method})"
      end
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this(test) test"
  end

  it "implicit method option" do
    ImplicitMethodOptionTest = create_test_class do
      def do_this
        value << "do_this"
      end
    end

    aspector "ImplicitMethodOptionTest#test" do
      before :do_this
    end

    o = ImplicitMethodOptionTest.new
    o.test
    o.value.should == %w"do_this test"
  end

  it "implicit methods option" do
    klass = create_test_class do
      def do_this
        value << "do_this"
      end
    end

    aspector klass, :methods => [:test] do
      before :do_this
    end

    o = ImplicitMethodOptionTest.new
    o.test
    o.value.should == %w"do_this test"
  end

end

