require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Aspector" do
  it "should work" do
    klass = create_test_class

    aspector(klass) do
      before :test do value << "do_before" end

      after  :test do value << "do_after"  end

      around :test do |&block|
        value   <<  "do_around_before"
        result  =   block.call
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

end
