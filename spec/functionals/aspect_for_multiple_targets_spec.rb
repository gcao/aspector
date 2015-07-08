require 'spec_helper'

RSpec.describe Aspector do
  let(:klass1) do
    ClassBuilder.build do
      def exec1
        values << 'exec1'
      end
    end
  end

  let(:klass2) do
    ClassBuilder.build do
      def exec2
        values << 'exec2'
      end
    end
  end

  let(:instance1) { klass1.new }
  let(:instance2) { klass2.new }

  let(:aspect_klass) do
    ClassBuilder.inherit(Aspector::Base) do
      attr_accessor :call_count

      def initialize
        @call_count = 0
      end

      before interception_arg: true do |interception|
        interception.aspect.call_count += 1
      end
    end
  end

  let(:aspect) { aspect_klass.new }

  context 'binding single aspect to multiple different targets' do
    before do
      aspect.apply klass1, method: :exec1
      aspect.apply klass2, methods: %w( exec2 )
    end

    it 'should work' do
      instance1.exec1
      instance2.exec2

      expect(aspect.call_count).to eq 2
      expect(instance1.values).to eq %w( exec1 )
      expect(instance2.values).to eq %w( exec2 )
    end
  end
end
