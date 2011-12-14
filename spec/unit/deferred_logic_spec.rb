require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Aspector
  describe DeferredLogic do
    it "should work with block" do
      klass = Class.new do
        def self.test; 'test'; end
      end

      logic = DeferredLogic.new(lambda{ test })

      logic.apply(klass).should == 'test'
    end

    it "block can take an argument" do
      logic = DeferredLogic.new(lambda{|arg| arg })

      logic.apply(Class.new, 'test').should == 'test'
    end

    it "should work with string" do
      klass = Class.new do
        def self.test; 'test'; end
      end

      logic = DeferredLogic.new('test')

      logic.apply(klass).should == 'test'
    end

  end
end

