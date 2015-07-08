require 'spec_helper'

RSpec.describe 'Aspector for a class' do
  context 'public class methods' do
    subject do
      ClassBuilder.build do
        class << self
          def values
            @values ||= []
          end

          def exec
            values << 'class-exec-result'
          end
        end
      end
    end

    context 'before aspect' do
      before do
        aspector(subject, class_methods: true) do
          before :exec do
            values << 'class-exec-before'
          end
        end
      end

      it 'should work' do
        subject.exec
        expect(subject.values).to eq %w( class-exec-before class-exec-result )
      end
    end

    context 'around aspect' do
      before do
        aspector(subject, class_methods: true) do
          around :exec do |proxy, &block|
            values << 'class-exec-around-before'
            result = proxy.call(&block)
            values << 'class-exec-around-after'
            result
          end
        end
      end

      it 'should work' do
        expected = %w( class-exec-around-before class-exec-result class-exec-around-after )
        subject.exec
        expect(subject.values).to eq expected
      end
    end

    context 'after aspect' do
      before do
        aspector(subject, class_methods: true) do
          after :exec do |result|
            values << 'class-exec-after'
            result
          end
        end
      end

      it 'should work' do
        subject.exec
        expect(subject.values).to eq %w( class-exec-result class-exec-after )
      end
    end
  end

  context 'private class methods' do
    subject do
      ClassBuilder.build do
        class << self
          def values
            @values ||= []
          end

          private

          def exec
            values << 'class-exec-result'
          end
        end
      end
    end

    context 'before aspect' do
      before do
        aspector(subject, class_methods: true) do
          before :exec do
            values << 'class-exec-before(public_methods_only)'
          end
        end

        aspector(subject, class_methods: true, private_methods: true) do
          before :exec do
            values << 'class-exec-before'
          end
        end
      end

      it 'should work' do
        subject.send(:exec)
        expect(subject.values).to eq %w( class-exec-before class-exec-result )
      end
    end

    context 'around aspect' do
      before do
        aspector(subject, class_methods: true) do
          around :exec do |proxy, &block|
            values << 'class-exec-around-before(public_methods_only)'
            result = proxy.call(&block)
            values << 'class-exec-around-after(public_methods_only)'
            result
          end
        end

        aspector(subject, class_methods: true, private_methods: true) do
          around :exec do |proxy, &block|
            values << 'class-exec-around-before'
            result = proxy.call(&block)
            values << 'class-exec-around-after'
            result
          end
        end
      end

      it 'should work' do
        expected = %w( class-exec-around-before class-exec-result class-exec-around-after )
        subject.send(:exec)
        expect(subject.values).to eq expected
      end
    end

    context 'after aspect' do
      before do
        aspector(subject, class_methods: true) do
          after :exec do |result|
            values << 'class-exec-after(public_methods_only)'
            result
          end
        end

        aspector(subject, class_methods: true, private_methods: true) do
          after :exec do |result|
            values << 'class-exec-after'
            result
          end
        end
      end

      it 'should work' do
        subject.send(:exec)
        expect(subject.values).to eq %w( class-exec-result class-exec-after )
      end
    end
  end
end
