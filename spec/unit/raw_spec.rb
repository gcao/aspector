require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Raw advices" do
  it "should work" do
    klass = create_test_class

    aspector(klass) do
      raw :test do
        alias test_without_aspect test
        def test
          value << "raw_before"
          test_without_aspect
        end
      end
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"raw_before test"
  end

  it "new methods should work" do
    klass = Class.new do
      aspector do
        raw :test do
          alias test_without_aspect test
          def test
            do_this
            test_without_aspect
          end
        end
      end

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

    obj = klass.new
    obj.test
    obj.value.should == %w"do_this test"
  end

end

