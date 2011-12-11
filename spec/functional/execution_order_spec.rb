require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Aspect execution order" do
  it "should work" do
    klass = Class.new do
      def value
        @value ||= []
      end

      def test
        value << "test"
      end

      def do_before1
        value << "do_before1"
      end

      def do_before2
        value << "do_before2"
      end

      def do_after1 result
        value << "do_after1"
        result
      end

      def do_after2 result
        value << "do_after2"
        result
      end

      def do_around1 &block
        value << "do_around_before1"
        result = block.call
        value << "do_around_after1"
        result
      end

      def do_around2 &block
        value << "do_around_before2"
        result = block.call
        value << "do_around_after2"
        result
      end

    end

    aspector(klass) do
      before :test, :do_before1
      after  :test, :do_after1
      around :test, :do_around1
      before :test, :do_before2
      after  :test, :do_after2
      around :test, :do_around2
    end

    obj = klass.new
    obj.test
    obj.value.should == %w"do_before1 do_before2 do_around_before1 do_around_before2 test
                           do_around_after2 do_around_after1 do_after1 do_after2"
  end
end
