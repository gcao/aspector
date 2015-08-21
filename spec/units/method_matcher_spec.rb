require 'spec_helper'

RSpec.describe Aspector::MethodMatcher do
  describe '#initialize' do
    pending
  end

  describe '#match?' do
    subject { described_class.new(match_data) }

    context 'String matching - when we want to match method by string name' do
      let(:method) { rand.to_s }
      let(:match_data) { method }

      it 'should match it' do
        expect(subject.match?(method)).not_to be_nil
      end
    end

    context 'Regular expression matching - when we want to match method by regexp' do
      let(:method) { rand.to_s + 'constant-part' }
      let(:match_data) { /constant/ }

      it 'should match it' do
        expect(subject.match?(method)).not_to be_nil
      end
    end

    context 'when we want to add more match data (multiple elements' do
      context 'and one of them matches' do
        let(:match_data) { %w( test1 test2 ) }

        it 'should not be nil' do
          expect(subject.match?(match_data.last)).not_to be_nil
        end
      end

      context 'and none of them match' do
        let(:match_data) { %w( test1 test2 ) }

        it 'should be nil' do
          expect(subject.match?('test3')).to be_nil
        end
      end

      context 'and all of them match' do
        let(:match_data) { [/test/, /te/] }

        it 'should not be nil' do
          expect(subject.match?('test2')).not_to be_nil
        end
      end
    end

    context 'deferred logic matching' do
      let(:match_data) { Aspector::DeferredLogic.new('') }
      let(:method) { double }

      before do
        expect(method)
          .to receive(:deferred_logic_results)
          .with(match_data)
          .and_return(/test/)
      end

      it 'should get aspect deferred logic results and match them' do
        expect(subject.match?('test', method)).not_to be_nil
      end
    end

    context 'deferred option matching' do
      let(:match_data) { Aspector::DeferredOption.new[:methods] }
      let(:method) { double }

      before do
        expect(method)
          .to receive(:options)
          .and_return(methods: /test/)
      end

      it 'should get aspect options value for a proper key and match it' do
        expect(subject.match?('test', method)).not_to be_nil
      end
    end
  end

  describe '#to_s' do
    let(:match_data) { [rand, rand] }
    subject { described_class.new(match_data) }

    it 'should use inspected match_data as a string representation of MethodMatcher' do
      expect(subject.to_s).to eq match_data.map(&:inspect).join(', ')
    end
  end
end
