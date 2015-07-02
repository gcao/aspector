require 'spec_helper'

RSpec.describe Aspector::Logger do
  let(:context) { '' }
  subject { described_class.new(context) }

  describe '.new' do
    it 'should store a context' do
      expect(subject.context).to eq context
    end

    it 'should set a log level' do
      expect(subject.level).to_not be_nil
    end
  end

  describe '#postfix' do
    pending
  end
end
