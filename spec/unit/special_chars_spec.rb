require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Special chars in method names" do
  ['?', '!', '='].each do |char|
    it "should work with methods whose name contains #{char}" do
      klass = Class.new do
        aspector do
          before "test#{char}", :do_this
        end

        def value
          @value ||= []
        end

        def do_this *args
          value << "do_this"
        end

        class_eval <<-CODE
          def test#{char} *args
            value << "test"
          end
        CODE
      end

      obj = klass.new
      obj.send "test#{char}", 1
      obj.value.should == %w"do_this test"
    end
  end

  it "should work with []" do
    klass = Class.new do
      aspector do
        before "[]", :do_this
      end

      def value
        @value ||= []
      end

      def do_this *args
        value << "do_this"
      end

      def [] *args
        value << "test"
      end
    end

    obj = klass.new
    obj[1]
    obj.value.should == %w"do_this test"
  end

  ['+', '-', '*', '/', '~', '|', '%', '&', '^', '<', '>', '[]', '[]='].each do |meth|
    it "should work with #{meth}" do
      klass = Class.new do
        aspector do
          before meth, :do_this
        end

        def value
          @value ||= []
        end

        def do_this *args
          value << "do_this"
        end
       
        define_method meth do |*args|
          value << "test"
        end
      end

      obj = klass.new
      obj.send meth, 1, 2
      obj.value.should == %w"do_this test"
    end
  end

end

