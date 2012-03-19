require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Aspector" do
  it "should work" do
    klass = create_test_class

    aspector(klass) do
      before :test do value << "do_before" end

      after  :test do |result|
        value << "do_after"
        result
      end

      around :test do |proxy, &block|
        value   <<  "do_around_before"
        result  =   proxy.call &block
        value   <<  "do_around_after"
        result
      end
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"do_before do_around_before test do_around_after do_after"
  end

  it "multiple aspects should work together" do
    klass = create_test_class
    aspector(klass) do
      before(:test) { value << 'first_aspect' }
    end

    aspector(klass) do
      before(:test) { value << 'second_aspect' }
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"second_aspect first_aspect test"
  end

  it "treating Aspect as regular class should work" do
    class TestAspect < Aspector::Base
      before(:test) { value << 'before_test' }
    end

    klass = create_test_class
    TestAspect.apply(klass)

    obj = klass.new
    obj.test
    obj.value.should == %w"before_test test"
  end

  it "can be applied multiple times" do
    aspect = Aspector do
      before(:test) { value << 'before_test' }
    end

    klass = create_test_class
    aspect.apply(klass)
    aspect.apply(klass)

    obj = klass.new
    obj.test
    obj.value.should == %w"before_test before_test test"
  end

  it "if new_methods_only is true, do not apply to existing methods" do
    aspect = Aspector do
      before(:test) { value << 'before_test' }
    end

    klass = create_test_class
    aspect.apply(klass, :new_methods_only => true)

    obj = klass.new
    obj.test
    obj.value.should == %w"test"
  end

  it "if new_methods_only is true, do apply to new methods" do
    aspect = Aspector do
      before(:test) { value << 'before_test' }
    end

    klass = Class.new do
      def value
        @value ||= []
      end
    end

    aspect.apply(klass, :new_methods_only => true)

    klass.send :define_method, :test do
      value << "test"
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"before_test test"
  end

  it "if old_methods_only is true, do apply to methods already defined" do
    aspect = Aspector do
      before(:test) { value << 'before_test' }
    end

    klass = create_test_class
    aspect.apply(klass, :old_methods_only => true)

    obj = klass.new
    obj.test
    obj.value.should == %w"before_test test"
  end

  it "if old_methods_only is true, do not apply to new methods" do
    aspect = Aspector do
      before(:test) { value << 'before_test' }
    end

    klass = Class.new do
      def value
        @value ||= []
      end
    end

    aspect.apply(klass, :old_methods_only => true)

    klass.send :define_method, :test do
      value << "test"
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"test"
  end

end
