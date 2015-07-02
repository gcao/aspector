require 'spec_helper'

RSpec.describe Aspector::DeferredLogic do
  describe '.new' do
    pending
  end

  describe '#apply' do
    context 'block in deferred logic' do
      let(:klass) do
        ClassBuilder.build do
          def self.exec
            'class-exec'
          end
        end
      end

      let(:logic) { described_class.new(-> { exec }) }

      it 'should work with block' do
        expect(logic.apply(klass)).to eq 'class-exec'
      end
    end

    context 'block with argument in deferred logic' do
      let(:argument_value) { rand }
      let(:klass) { ClassBuilder.build }
      let(:logic) { described_class.new(->(arg) { arg }) }

      it 'block can take an argument' do
        expect(logic.apply(klass, argument_value)).to eq argument_value
      end
    end
  end
end
