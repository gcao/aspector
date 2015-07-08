require 'spec_helper'

RSpec.describe 'Aspector options access' do
  subject { klass.new }
  let(:interception_options) { { rand => rand } }

  context 'accessing interception options' do
    let(:klass) do
      ClassBuilder.build do
        attr_accessor :interception_options
      end
    end

    before do
      aspect.apply klass, interception_options.merge(method: :exec)
    end

    context 'before aspect' do
      let(:aspect) do
        ClassBuilder.inherit(Aspector::Base) do
          default aspect_field: 60

          before interception_arg: true do |interception|
            self.interception_options = interception.options
          end
        end
      end

      it 'should be able to reach interception options that were merged with aspect options' do
        subject.exec
        expected = interception_options.merge(method: :exec).merge(aspect_field: 60)
        expect(subject.interception_options).to eq expected
      end

      it 'still should exec original method' do
        subject.exec
        expect(subject.values).to eq %w( exec-result )
      end
    end

    context 'before_filter aspect' do
      let(:aspect) do
        ClassBuilder.inherit(Aspector::Base) do
          default aspect_field: 60

          before_filter interception_arg: true do |interception|
            self.interception_options = interception.options
          end
        end
      end

      it 'should be able to reach interception options that were merged with aspect options' do
        subject.exec
        expected = interception_options.merge(method: :exec).merge(aspect_field: 60)
        expect(subject.interception_options).to eq expected
      end

      it 'still should exec original method' do
        subject.exec
        expect(subject.values).to eq %w( exec-result )
      end
    end

    context 'around aspect' do
      let(:aspect) do
        ClassBuilder.inherit(Aspector::Base) do
          default aspect_field: 60

          around interception_arg: true do |interception, proxy, &block|
            self.interception_options = interception.options
            proxy.call(&block)
          end
        end
      end

      it 'should be able to reach interception options that were merged with aspect options' do
        subject.exec
        expected = interception_options.merge(method: :exec).merge(aspect_field: 60)
        expect(subject.interception_options).to eq expected
      end

      it 'still should exec original method' do
        subject.exec
        expect(subject.values).to eq %w( exec-result )
      end
    end

    context 'after aspect' do
      let(:aspect) do
        ClassBuilder.inherit(Aspector::Base) do
          default aspect_field: 60

          after interception_arg: true do |interception, result|
            self.interception_options = interception.options
            result
          end
        end
      end

      it 'should be able to reach interception options that were merged with aspect options' do
        subject.exec
        expected = interception_options.merge(method: :exec).merge(aspect_field: 60)
        expect(subject.interception_options).to eq expected
      end

      it 'still should exec original method' do
        subject.exec
        expect(subject.values).to eq %w( exec-result )
      end
    end
  end
end
