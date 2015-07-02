require 'spec_helper'

RSpec.describe Aspector do
  let(:klass) { ClassBuilder.build }
  subject { klass.new }

  context 'binding multiple aspects in a single place' do
    before do
      aspector(klass) do
        before(:exec) { values << 'first-aspect' }
      end

      aspector(klass) do
        before(:exec) { values << 'second-aspect' }
      end
    end

    it 'should work' do
      subject.exec
      expect(subject.values).to eq %w( second-aspect first-aspect exec-result )
    end
  end

  context 'when we try to treat Aspect as a regular class' do
    let(:aspect_klass) do
      ClassBuilder.inherit(Aspector::Base) do
        before(:exec) { values << 'before-exec' }
      end
    end

    before do
      aspect_klass.apply(klass)
    end

    it 'should work' do
      subject.exec
      expect(subject.values).to eq %w( before-exec exec-result )
    end
  end

  context 'when we want to apply aspect multiple times' do
    let(:aspect_klass) do
      Aspector do
        before(:exec) { values << 'before-exec' }
      end
    end

    before do
      aspect_klass.apply(klass)
      aspect_klass.apply(klass)
    end

    it 'should apply aspect multiple times' do
      subject.exec
      expect(subject.values).to eq %w( before-exec before-exec exec-result )
    end
  end

  context 'when we set new_methods_only to true' do
    let(:aspect_klass) do
      Aspector do
        before(:exec) { values << 'before-exec' }
      end
    end

    before do
      aspect_klass.apply(klass, new_methods_only: true)
    end

    context 'and we try to apply it to already existing method' do
      it 'should not apply to existing methods' do
        subject.exec
        expect(subject.values).to eq %w( exec-result )
      end
    end

    context 'and we try to apply it to a new method' do
      let(:klass) do
        ClassBuilder.raw do
          def values
            @values ||= []
          end
        end
      end

      before do
        klass.send :define_method, :exec do
          values << 'exec-result'
        end
      end

      it 'should apply to new methods' do
        subject.exec
        expect(subject.values).to eq %w( before-exec exec-result )
      end
    end
  end

  context 'when we set existing_methods_only to true' do
    let(:aspect_klass) do
      Aspector do
        before(:exec) { values << 'before-exec' }
      end
    end

    before do
      aspect_klass.apply(klass, existing_methods_only: true)
    end

    context 'and we try to apply it to already existing method' do
      it 'should apply to existing methods' do
        subject.exec
        expect(subject.values).to eq %w( before-exec exec-result )
      end
    end

    context 'and we try to apply it to a new method' do
      let(:klass) do
        ClassBuilder.raw do
          def values
            @values ||= []
          end
        end
      end

      before do
        klass.send :define_method, :exec do
          values << 'exec-result'
        end
      end

      it 'should not apply to new methods' do
        subject.exec
        expect(subject.values).to eq %w( exec-result )
      end
    end
  end
end
