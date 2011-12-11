require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Aspector for eigen class" do
  it "should work" do
    klass = Class.new do
      class << self
        def value
          @value ||= []
        end

        def test
          value << "test"
        end

        def do_before
          value << "do_before"
        end

        def do_after result
          value << "do_after"
          result
        end

        def do_around &block
          value << "do_around_before"
          result = block.call
          value << "do_around_after"
          result
        end
      end
    end

    aspector(klass, :eigen_class => true) do
      before :test, :do_before
      after  :test, :do_after
      around :test, :do_around
    end

    klass.test
    klass.value.should == %w"do_before do_around_before test do_around_after do_after"
  end

  it "new methods" do
    klass = Class.new do
      class << self
        def value
          @value ||= []
        end

        def do_before
          value << "do_before"
        end

        def do_after result
          value << "do_after"
          result
        end

        def do_around &block
          value << "do_around_before"
          result = block.call
          value << "do_around_after"
          result
        end
      end
    end

    aspector(klass, :eigen_class => true) do
      before :test, :do_before
      after  :test, :do_after
      around :test, :do_around
    end

    klass.class_eval do
      class << self
        def test
          value << "test"
        end
      end
    end

    klass.test
    klass.value.should == %w"do_before do_around_before test do_around_after do_after"
  end

end
