require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Aspector::Base" do
  it "Default options" do
    aspect = Aspector do
      default :test => 'value'
    end

    aspect.default_options[:test].should == 'value'
  end

  it "deferred_option" do
    klass = Class.new do
      def value
        @value ||= []
      end

      def test
        value << "test"
      end
    end

    aspect = Aspector do
      before options[:methods] do
        value << "do_this"
      end
    end

    aspect.apply(klass, :methods => [:test])

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this test"
  end
end
