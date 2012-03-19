require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Around advices" do
  it "should work" do
    klass = create_test_class do
      def do_this proxy, &block
        value << "before"
        result = proxy.call &block
        value << "after"
        result
      end
    end

    aspector(klass) do
      around :test, :do_this
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"before test after"
  end

  it "logic in block" do
    klass = create_test_class

    aspector(klass) do
      around :test do |proxy, &block|
        value << "before"
        result = proxy.call &block
        value << "after"
        result
      end
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"before test after"
  end

  it "method_arg" do
    klass = create_test_class do
      def do_this method, proxy, &block
        value << "before(#{method})"
        result = proxy.call &block
        value << "after(#{method})"
        result
      end
    end

    aspector(klass) do
      around :test, :do_this, :method_arg => true
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"before(test) test after(test)"
  end
end

