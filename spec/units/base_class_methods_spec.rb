require 'spec_helper'

RSpec.describe 'Aspector::Base class methods' do
  subject { ClassBuilder.inherit(Aspector::Base) }

  describe '.enable' do
    pending
  end

  describe '.disable' do
    pending
  end

  describe '.logger' do
    pending
  end

  describe '.advices' do
    pending
  end

  describe '.default_options' do
    pending
  end

  describe '.apply' do
    pending
  end

  describe '.default' do
    context 'when there are no default options' do
      let(:options) { { rand => rand } }

      before do
        subject.instance_variable_set(:'@default_options', nil)
      end

      it 'should assign provided options' do
        subject.send(:default, options)

        expect(subject.instance_variable_get(:'@default_options')).to eq options
      end
    end

    context 'when there are default options' do
      let(:options) { { rand => rand } }
      let(:default_options) { { rand => rand } }

      before do
        subject.instance_variable_set(:'@default_options', default_options)
      end

      it 'should merge with existing options' do
        subject.send(:default, options)

        defaults = options.merge(default_options)
        expect(subject.instance_variable_get(:'@default_options')).to eq defaults
      end
    end
  end

  describe '.before' do
    subject do
      ClassBuilder.inherit(Aspector::Base) do
        before :test, :do_before
      end
    end

    let(:advices) { subject.send(:advices) }
    let(:advice) { advices.first }

    it 'should create an advice' do
      expect(subject.send(:advices).size).to eq 1
    end

    it 'created advice should be a before one' do
      expect(advice.before?).to eq true
      expect(advice.before_filter?).to eq false
      expect(advice.after?).to eq false
      expect(advice.around?).to eq false
      expect(advice.raw?).to eq false
    end

    it 'skip_if_false for this advice should not be true' do
      expect(advice.options[:skip_if_false]).not_to eq true
    end

    it 'should create a advice with a do_before method' do
      expect(advice.with_method).to eq :do_before
    end
  end

  describe '.before_filter' do
    subject do
      ClassBuilder.inherit(Aspector::Base) do
        before_filter :test, :do_before
      end
    end

    let(:advices) { subject.send(:advices) }
    let(:advice) { advices.first }

    it 'should create an advice' do
      expect(subject.send(:advices).size).to eq 1
    end

    it 'created advice should be only a before one' do
      expect(advice.before_filter?).to eq true
      expect(advice.before?).to eq false
      expect(advice.after?).to eq false
      expect(advice.around?).to eq false
      expect(advice.raw?).to eq false
    end

    it 'should create a advice with a do_before method' do
      expect(advice.with_method).to eq :do_before
    end
  end

  describe '.after' do
    subject do
      ClassBuilder.inherit(Aspector::Base) do
        after :test, :do_after
      end
    end

    let(:advices) { subject.send(:advices) }
    let(:advice) { advices.first }

    it 'should create an advice' do
      expect(subject.send(:advices).size).to eq 1
    end

    it 'created advice should be a before one' do
      expect(advice.after?).to eq true
      expect(advice.before_filter?).to eq false
      expect(advice.before?).to eq false
      expect(advice.around?).to eq false
      expect(advice.raw?).to eq false
    end

    it 'skip_if_false for this advice should not be true' do
      expect(advice.options[:skip_if_false]).not_to eq true
    end

    it 'should create a advice with a do_after method' do
      expect(advice.with_method).to eq :do_after
    end
  end

  describe '.around' do
    subject do
      ClassBuilder.inherit(Aspector::Base) do
        around :test, :do_around
      end
    end

    let(:advices) { subject.send(:advices) }
    let(:advice) { advices.first }

    it 'should create an advice' do
      expect(subject.send(:advices).size).to eq 1
    end

    it 'created advice should be a around one' do
      expect(advice.after?).to eq false
      expect(advice.before?).to eq false
      expect(advice.around?).to eq true
      expect(advice.raw?).to eq false
    end

    it 'skip_if_false for this advice should not be true' do
      expect(advice.options[:skip_if_false]).not_to eq true
    end

    it 'should create a advice with a do_around method' do
      expect(advice.with_method).to eq :do_around
    end
  end

  describe '.raw' do
    subject do
      ClassBuilder.inherit(Aspector::Base) do
        raw :test do
        end
      end
    end

    let(:advices) { subject.send(:advices) }
    let(:advice) { advices.first }

    it 'should create an advice' do
      expect(subject.send(:advices).size).to eq 1
    end

    it 'created advice should be a around one' do
      expect(advice.after?).to eq false
      expect(advice.before_filter?).to eq false
      expect(advice.before?).to eq false
      expect(advice.around?).to eq false
      expect(advice.raw?).to eq true
    end

    it 'skip_if_false for this advice should not be true' do
      expect(advice.options[:skip_if_false]).not_to eq true
    end
  end

  describe '.target' do
    context 'when there is no code and no block' do
      let(:code) { nil }

      it 'should raise ArgumentError' do
        expect { subject.send(:target, code) }.to raise_error(ArgumentError)
      end
    end

    context 'when there is code and no block given' do
      let(:code) { true }

      it 'should not raise ArgumentError' do
        expect { subject.send(:target, code) {} }.not_to raise_error
      end
    end

    context 'when there is block given and no code' do
      let(:code) { nil }

      it 'should not raise ArgumentError' do
        expect { subject.send(:target, code) {} }.not_to raise_error
      end
    end

    context 'when there is code and block given' do
      let(:code) { true }

      it 'should not raise ArgumentError' do
        expect { subject.send(:target, code) {} }.not_to raise_error
      end
    end
  end

  describe '.options' do
    it 'should return DeferredOptions instance' do
      expect(subject.send(:options)).to be_kind_of Aspector::DeferredOption
    end
  end

  describe '._deferred_logics_' do
    context 'when there is nothing in @deferred_logics' do
      pending
    end

    context 'when there is value in @deferred_logics' do
      pending
    end
  end

  describe '._create_advice_' do
    pending
  end
end
