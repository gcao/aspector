require 'spec_helper'

RSpec.describe 'Aspects on private methods' do
  subject { klass.new }

  let(:klass) do
    ClassBuilder.build do
      private :exec
    end
  end

  context 'before aspect' do
    before do
      aspector(klass) do
        before :exec do
          values << 'exec-before(public_methods_only)'
        end
      end

      aspector(klass, private_methods: true) do
        before :exec do
          values << 'exec-before'
        end
      end
    end

    it 'should bind only the aspect that binds to private methods' do
      subject.send :exec
      expect(subject.values).to eq %w( exec-before exec-result )
    end
  end

  context 'around aspect' do
    before do
      aspector(klass) do
        around :exec do |proxy, &block|
          values << 'exec-around-before(public_methods_only)'
          result = proxy.call(&block)
          values << 'exec-around-after(public_methods_only)'
          result
        end
      end

      aspector(klass, private_methods: true) do
        around :exec do |proxy, &block|
          values << 'exec-around-before'
          result = proxy.call(&block)
          values << 'exec-around-after'
          result
        end
      end
    end

    it 'should bind only the aspect that binds to private methods' do
      subject.send :exec
      expect(subject.values).to eq %w( exec-around-before exec-result exec-around-after )
    end
  end

  context 'after aspect' do
    before do
      aspector(klass) do
        after :exec do |result|
          values << 'exec-after(public_methods_only)'
          result
        end
      end

      aspector(klass, private_methods: true) do
        after :exec do |result|
          values << 'exec-after'
          result
        end
      end
    end

    it 'should bind only the aspect that binds to private methods' do
      subject.send :exec
      expect(subject.values).to eq %w( exec-result exec-after )
    end
  end
end
