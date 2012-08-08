require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Design by Contract" do
  it "should work" do
    klass = Class.new do
      include Aspector::DesignByContract

      precond { assert false, 'message' }
      def do_something
      end
    end

    obj = klass.new
    obj.should_receive(:assert).with(false, 'message')
    obj.do_something
  end
end

