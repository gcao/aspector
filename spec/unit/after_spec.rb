require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "After advices" do
  it "should work" do
    klass = create_test_class do
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
    klass = create_test_class do
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

  it "new result will be returned by default" do
    klass = create_test_class

    aspector(klass) do
      after :test do |result|
        value << "do_after"
        'do_after'
      end
    end

    obj = klass.new
    obj.test.should == 'do_after'
    obj.value.should == %w"test do_after"
  end

  it "result_arg set to false" do
    klass = create_test_class do
      def test
        value << "test"
        'test'
      end
    end

    aspector(klass) do
      after :test, :result_arg => false do
        value << "do_after"
        'do_after'
      end
    end

    obj = klass.new
    obj.test.should == 'test'
    obj.value.should == %w"test do_after"
  end

  it "logic in block" do
    klass = create_test_class

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

