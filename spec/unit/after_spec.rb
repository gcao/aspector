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

  it "context_arg" do
    klass = Class.new do
      def value
        @value ||= []
      end

      def test
        value << "test"
      end

      def do_this context, result
        value << "do_this"
        result
      end
    end

    aspector(klass) do
      after :test, :do_this, :context_arg => true
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"test do_this"
  end

  it "result_arg set to false" do
    klass = Class.new do
      def value
        @value ||= []
      end

      def test
        value << "test"
        'test'
      end

      def do_this
        value << "do_this"
      end
    end

    aspector(klass) do
      after :test, :do_this, :result_arg => false
    end

    obj = klass.new
    obj.test.should == 'test'
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
