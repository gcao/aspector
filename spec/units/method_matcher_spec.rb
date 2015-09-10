require 'spec_helper'

RSpec.describe Aspector::MethodMatcher do
  describe '#initialize' do
    pending
  end

  describe '#any?' do
    subject { described_class.new(match_data) }
    let(:match1) { double }
    let(:match2) { double }
    let(:match_data) { [match1, match2] }
    let(:method) { double }
    let(:aspect) { double }

    context 'should check for every if none' do
      before do
        expect(subject)
          .to receive(:matches?)
          .with(match1, method, aspect)
          .and_return(false)

        expect(subject)
          .to receive(:matches?)
          .with(match2, method, aspect)
          .and_return(false)
      end

      it { expect(subject.any?(method, aspect)).to eq false }
    end
  end

  describe '#to_s' do
    let(:match_data) { [rand, rand] }
    subject { described_class.new(match_data) }

    it 'should use inspected match_data as a string representation of MethodMatcher' do
      expect(subject.to_s).to eq match_data.map(&:inspect).join(', ')
    end
  end

  describe '#matches?' do
    subject { described_class.new([match_item]) }

    context 'String matching - when we want to match method by string name' do
      let(:method) { rand.to_s }
      let(:match_item) { method }

      it 'should match it' do
        expect(subject.send(:matches?, match_item, method)).to eq true
      end
    end

    context 'Regular expression matching - when we want to match method by regexp' do
      let(:method) { rand.to_s + 'constant-part' }
      let(:match_item) { /constant/ }

      it 'should match it' do
        expect(subject.send(:matches?, match_item, method)).to eq true
      end
    end

    context 'deferred logic matching' do
      let(:match_item) { Aspector::DeferredLogic.new('') }
      let(:method) { double }

      before do
        expect(method)
          .to receive(:deferred_logic_results)
          .with(match_item)
          .and_return(/test/)
      end

      it 'should get aspect deferred logic results and match them' do
        expect(subject.send(:matches?, match_item, 'test', method)).to eq true
      end
    end

    context 'deferred option matching' do
      let(:match_item) { Aspector::DeferredOption.new[:methods] }
      let(:method) { double }

      before do
        expect(method)
          .to receive(:options)
          .and_return(methods: /test/)
      end

      it 'should get aspect options value for a proper key and match it' do
        expect(subject.send(:matches?, match_item, 'test', method)).to eq true
      end
    end

    context 'unsupported item class' do
      let(:method) { rand.to_s }
      let(:match_item) { [] }

      it 'should fail with a proper exception' do
        error = described_class::UnsupportedItemClass
        expect { subject.send(:matches?, match_item, method) }.to raise_error error
      end
    end
  end
end
