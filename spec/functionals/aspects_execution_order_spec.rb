require 'spec_helper'

RSpec.describe 'Aspect execution order' do
  let(:klass) { ClassBuilder.build }
  subject { klass.new }

  context 'when we apply aspects in certain order' do
    before do
      aspector(klass) do
        before :exec do
          values << 'exec-before1'
        end

        after :exec do |result|
          values << 'exec-after1'
          result
        end

        around :exec do |proxy, &block|
          values << 'exec-around-before1'
          result = proxy.call(&block)
          values << 'exec-around-after1'
          result
        end

        before :exec do
          values << 'exec-before2'
        end

        after :exec do |result|
          values << 'exec-after2'
          result
        end

        around :exec do |proxy, &block|
          values << 'exec-around-before2'
          result = proxy.call(&block)
          values << 'exec-around-after2'
          result
        end
      end
    end

    it 'should use this order' do
      expected = %w(
        exec-before1
        exec-before2
        exec-around-before1
        exec-around-before2
        exec-result
        exec-around-after2
        exec-around-after1
        exec-after1
        exec-after2
      )

      subject.exec
      expect(subject.values).to eq expected
    end
  end
end
