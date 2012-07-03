require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Aspector::Base" do
  it "default options" do
    aspect = Aspector do
      default :test => 'value'
    end

    aspect.send(:aop_default_options)[:test].should == 'value'
  end

  it "#options is used to access options set when aspect is applied" do
    klass = create_test_class

    aspect = Aspector do
      before options[:methods] do
        value << "do_this"
      end
    end

    aspect.apply(klass, :methods => :test)

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this test"
  end

  it "#apply" do
    klass = create_test_class

    aspect = Aspector do
      before :test do value << "do_before" end
    end

    aspect.apply(klass)

    obj = klass.new
    obj.test
    obj.value.should == %w"do_before test"
  end

  it "#apply to multiple targets at once" do
    klass = create_test_class
    klass2 = create_test_class

    aspect = Aspector do
      before :test do value << "do_before" end
    end

    aspect.apply(klass, klass2)

    obj = klass.new
    obj.test
    obj.value.should == %w"do_before test"

    obj2 = klass2.new
    obj2.test
    obj2.value.should == %w"do_before test"
  end

  it "use #target to add method to target class/module" do
    klass = create_test_class

    aspector(klass) do
      target do
        def do_this
          value << "do_this"
        end
      end

      before :test, :do_this
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this test"
  end

  it "#target takes aspect as argument" do
    klass = create_test_class

    class TargetArgumentTestAspect < Aspector::Base
      target do |aspect|
        define_method :do_this do
          value << "do_this(#{aspect.class})"
        end
      end

      before :test, :do_this
    end

    TargetArgumentTestAspect.apply(klass)

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this(TargetArgumentTestAspect) test"
  end

  it "should not fail if method does not exist" do
    klass = Class.new

    aspect = Aspector do
      before options[:methods] do
        # dummy advice
      end
    end

    aspect.apply(klass, :methods => 'not_exist')
  end

end

