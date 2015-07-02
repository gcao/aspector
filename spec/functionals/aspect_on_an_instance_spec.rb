require 'spec_helper'

RSpec.describe 'Advices on private methods' do
  subject { klass.new }

  let(:klass) do
    ClassBuilder.build
  end

  let(:instance1) { klass.new }
  let(:instance2) { klass.new }

  context 'before aspect' do
    before do
      aspector(instance1) do
        before :exec do
          values << 'exec-before'
        end
      end
    end

    it 'should bind only to one instance to which we want to bind' do
      instance1.exec
      instance2.exec
      expect(instance1.values).to eq %w( exec-before exec-result )
      expect(instance2.values).to eq %w( exec-result )
    end
  end

  context 'around aspect' do
    before do
      aspector(instance1) do
        around :exec do |proxy, &block|
          values << 'exec-around-before'
          result = proxy.call(&block)
          values << 'exec-around-after'
          result
        end
      end
    end

    it 'should bind only to one instance to which we want to bind' do
      instance1.exec
      instance2.exec
      expect(instance1.values).to eq %w( exec-around-before exec-result exec-around-after )
      expect(instance2.values).to eq %w( exec-result )
    end
  end

  context 'after aspect' do
    before do
      aspector(instance1) do
        after :exec do |_result|
          values << 'exec-after'
        end
      end
    end

    it 'should bind only the aspect that binds to private methods' do
      instance1.exec
      instance2.exec
      expect(instance1.values).to eq %w( exec-result exec-after )
      expect(instance2.values).to eq %w( exec-result )
    end
  end
end
