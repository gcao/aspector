require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Aspector::Base class methods" do
  it "before" do
    klass = Class.new(Aspector::Base) do
      before :test, :do_before
    end

    klass.send(:_advices_).size.should == 1
    advice = klass.send(:_advices_).first
    advice.before?.should be_true
    advice.options[:skip_if_false].should_not be_true
    advice.with_method.should == 'do_before'
  end

  it "before_filter" do
    klass = Class.new(Aspector::Base) do
      before_filter :test, :do_before
    end

    klass.send(:_advices_).size.should == 1
    advice = klass.send(:_advices_).first
    advice.before?.should be_true
    advice.options[:skip_if_false].should be_true
    advice.with_method.should == 'do_before'
  end

end
