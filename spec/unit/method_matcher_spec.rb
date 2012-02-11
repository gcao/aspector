require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Aspector
  describe MethodMatcher do
    it "should match String" do
      MethodMatcher.new('test').match?('test').should_not be_nil
    end

    it "should match regular expression" do
      MethodMatcher.new(/test/).match?('test').should_not be_nil
    end

    it "should return true if any item matches" do
      MethodMatcher.new('test1', 'test2').match?('test2').should_not be_nil
    end

    it "should return nil if none matches" do
      MethodMatcher.new('test1', 'test2').match?('test3').should be_nil
    end

    it "deferred logic" do
      logic = DeferredLogic.new ""
      matcher = MethodMatcher.new(logic)

      aspect = mock(Aspector::Base)
      aspect.should_receive(:_deferred_logic_results_).with(logic).once.and_return(/test/)

      matcher.match?('test', aspect).should_not be_nil
    end

    it "deferred option" do
      option = DeferredOption.new[:methods]
      matcher = MethodMatcher.new(option)

      aspect = mock(Aspector::Base)
      aspect.should_receive(:options).once.and_return({:methods => /test/})

      matcher.match?('test', aspect).should_not be_nil
    end

  end
end

