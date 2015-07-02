require 'spec_helper'

RSpec.describe Aspector::Logging do
  subject { described_class }
  let(:context) { double }

  describe '.get_logger' do
    before do
      subject.instance_variable_set('@logger', logger)
    end

    after do
      subject.instance_variable_set('@logger', nil)
    end

    let(:logger) { nil }
    let(:klass_name) { 'NonExisting' }

    context 'and given logger class doesnt exist' do
      before do
        expect(ENV)
          .to receive(:[])
          .and_return(klass_name)
          .at_least(:once)

        expect($stderr)
          .to receive(:puts)
          .with("#{klass_name} is not a valid constant name!")
      end

      it 'should use Aspector::Logger' do
        expect(subject.get_logger(context)).to be_instance_of(Aspector::Logger)
      end
    end

    context 'and given logger class exists' do
      let(:dummy_logger) { 'DummyLogger' }

      before do
        expect(ENV)
          .to receive(:[])
          .and_return(dummy_logger)
          .at_least(:once)

        expect(Object)
          .to receive(:const_get)
          .with(dummy_logger)
          .and_return(Aspector::Logger)
      end

      it 'should use it' do
        expect(subject.get_logger(context)).to be_instance_of(Aspector::Logger)
      end
    end
  end

  describe '.deconstantize' do
    context 'and given logger class doesnt exist' do
      let(:klass_name) { 'NonExisting' }

      before do
        expect($stderr)
          .to receive(:puts)
          .with("#{klass_name} is not a valid constant name!")
      end

      it 'should return internal logger class' do
        expect(subject.send(:deconstantize, klass_name)).to eq Aspector::Logger
      end
    end

    context 'and given logger class exists' do
      let(:klass_name) { 'Aspector::Logger' }

      before do
        expect($stderr)
          .not_to receive(:puts)
      end

      it 'should return it deconstantized' do
        expect(subject.send(:deconstantize, klass_name)).to eq Aspector::Logger
      end
    end
  end
end
