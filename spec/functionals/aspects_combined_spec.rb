require 'spec_helper'

RSpec.describe 'Aspects combined' do
  let(:klass) { ClassBuilder.build }
  subject { klass.new }

  context 'when we want to combine multiple different aspects' do
    before do
      aspector(klass) do
        before :exec do
          values << 'exec-before'
        end

        after :exec do |result|
          values << 'exec-after'
          result
        end

        around :exec do |proxy, &block|
          values << 'exec-around-before'
          result = proxy.call(&block)
          values << 'exec-around-after'
          result
        end
      end
    end

    it 'should work' do
      expected = %w(
        exec-before exec-around-before exec-result exec-around-after exec-after
      )

      subject.exec
      expect(subject.values).to eq expected
    end
  end
end
