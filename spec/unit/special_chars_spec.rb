require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "special chars in method names" do
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

        define_method "test#{char}" do |*args|
          value << "test"
        end
      end

      obj = klass.new
      obj.send "test#{char}", 1
      obj.value.should == %w"do_this test"
    end
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

describe "special chars in class method names" do
  ['?', '!', '='].each do |char|
    it "should work with methods whose name contains #{char}" do
      Object.send :define_method, :meth_with_special_char do
        "test#{char}"
      end

      klass = Class.new do
        aspector :class_methods => true do
          before meth_with_special_char, :do_this
        end

        class << self
          def value
            @value ||= []
          end

          def do_this *args
            value << "do_this"
          end

          define_method meth_with_special_char do |*args|
            value << "test"
          end
        end
      end

      klass.send meth_with_special_char, 1
      klass.value.should == %w"do_this test"
    end
  end

  ['+', '-', '*', '/', '~', '|', '%', '&', '^', '<', '>', '[]', '[]='].each do |meth|
    it "should work with #{meth}" do
      Object.send :define_method, :meth_with_special_char do
        meth
      end

      klass = Class.new do
        aspector :class_methods => true do
          before meth_with_special_char, :do_this
        end

        class << self
          def value
            @value ||= []
          end

          def do_this *args
            value << "do_this"
          end

          define_method meth_with_special_char do |*args|
            value << "test"
          end
        end
      end

      klass.send meth_with_special_char, 1, 2
      klass.value.should == %w"do_this test"
    end
  end

end

