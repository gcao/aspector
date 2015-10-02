require 'spec_helper'

RSpec.describe Aspector do
  let(:klass) do
    ClassBuilder.build do
      attr_accessor :counter

      def initialize
        @counter = 0
      end

      def exec
        values << 'exec'
      end

      def count
        self.counter += 1
      end
    end
  end

  let(:instance) { klass.new }

  let(:aspect_klass) do
    ClassBuilder.inherit(Aspector::Base) do
      attr_accessor :call_count

      def initialize
        @call_count = 0
      end

      before interception_arg: true do |interception|
        interception.aspect.call_count += 1
      end

      before :count
    end
  end

  let(:aspect) { aspect_klass.new }

  context 'binding single aspect multiple times to a single element' do
    let(:amount) { rand(100) }

    before do
      amount.times { aspect.apply klass, method: :exec }
    end

    it 'should apply it multiple times and wrap it' do
      instance.exec

      expect(aspect.call_count).to eq amount
      expect(instance.counter).to eq amount
      expect(instance.values).to eq %w( exec )
    end
  end
end
