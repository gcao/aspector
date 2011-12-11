require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Miscellaneous" do
  it "#apply" do
    klass = Class.new do
      def value
        @value ||= []
      end

      def test
        value << "test"
      end

      def do_this
        value << "do_this"
      end
    end

    aspect = Aspector do
      before :test, :do_this
    end

    aspect.apply(klass)

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this test"
  end

  it "can add method to target" do
     klass = Class.new do
      def value
        @value ||= []
      end

      def test
        value << "test"
      end
    end

    aspect = Aspector do
      target do
        def do_this
          value << "do_this"
        end
      end

      before :test, :do_this
    end

    aspect.apply(klass)

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this test"
  end

  it "target takes String too" do
     klass = Class.new do
      def value
        @value ||= []
      end

      def test
        value << "test"
      end
    end

    aspect = Aspector do
      target '
        def do_this
          value << "do_this"
        end
      '

      before :test, :do_this
    end

    aspect.apply(klass)

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this test"
  end

end
