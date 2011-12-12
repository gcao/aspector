require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Around advices" do
  it "should work" do
    klass = create_test_class do
      def do_this &block
        value << "before"
        result = block.call
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
      around :test do |&block|
        value << "before"
        result = block.call
        value << "after"
        result
      end
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"before test after"
  end
end

