require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Advices on private methods" do
  it "should work" do
    klass = create_test_class do
      private :test
    end

    aspector(klass) do
      before :test do value << "do_before(public_methods_only)" end
    end

    aspector(klass, :private_methods => true) do
      before :test do value << "do_before" end
    end

    obj = klass.new
    obj.send :test
    obj.value.should == %w"do_before test"
  end
end
