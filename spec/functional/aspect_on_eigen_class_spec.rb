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
      end
    end

    aspector(klass, :eigen_class => true) do
      before :test do value << "do_before" end

      after  :test do |result|
        value << "do_after"
        result
      end

      around :test do |&block|
        value   <<  "do_around_before"
        result  =   block.call
        value   <<  "do_around_after"
        result
      end
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
      end
    end

    aspector(klass, :eigen_class => true) do
      before :test do value << "do_before" end

      after  :test do |result|
        value << "do_after"
        result
      end

      around :test do |&block|
        value   <<  "do_around_before"
        result  =   block.call
        value   <<  "do_around_after"
        result
      end
    end

    klass.instance_eval do
      def test
        value << "test"
      end
    end

    klass.test
    klass.value.should == %w"do_before do_around_before test do_around_after do_after"
  end

end
