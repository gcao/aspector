require 'spec_helper'

RSpec.describe Aspector::Base do
  let(:klass) { ClassBuilder.build }
  let(:aspect) do
    Aspector do
      before :exec do
        values << 'do_before'
      end
    end
  end

  subject { klass.new }

  describe 'default options' do
    context 'when we create aspector with default options' do
      subject do
        Aspector do
          default exec: 'value'
        end
      end

      it 'should store them' do
        expect(subject.send(:storage).default_options[:exec]).to eq 'value'
      end
    end
  end

  describe '#apply' do
    context 'applying to a single target' do
      it 'should apply a given code to the method' do
        aspect.apply(klass)
        subject.exec
        expect(subject.values).to eq %w( do_before exec-result )
      end
    end

    context 'applying to multiple targets at once' do
      let(:klass1) { ClassBuilder.build }
      let(:klass2) { ClassBuilder.build }

      let(:instance1) { klass1.new }
      let(:instance2) { klass2.new }

      before { aspect.apply(klass1, klass2) }

      it 'should apply to all the targets' do
        instance1.exec
        expect(instance1.values).to eq %w( do_before exec-result )

        instance2.exec
        expect(instance2.values).to eq %w( do_before exec-result )
      end
    end

    context 'when we try to apply to nonexisting method' do
      let(:aspect) do
        Aspector do
          before do
            # dummy advice
          end
        end
      end

      it 'should not do anything (should not fail)' do
        expect { aspect.apply(klass, methods: 'not_exist') }.not_to raise_error
      end
    end
  end

  describe '#target' do
    context 'adding method to targeted class/module' do
      before do
        aspector(klass) do
          target do
            def before_exec
              values << 'before-exec'
            end
          end

          before :exec, :before_exec
        end
      end

      it 'should add to target' do
        subject.exec
        expect(subject.values).to eq %w( before-exec exec-result )
      end
    end

    context 'when we provide an aspect as an argument to a #target method' do
      let(:aspect_class) do
        Class.new(Aspector::Base) do
          target do |aspect|
            define_method :before_exec do
              values << "before_exec(#{aspect.class})"
            end
          end

          before :exec, :before_exec
        end
      end

      it 'should add it to target' do
        aspect_class.apply(klass)

        subject.exec
        expect(subject.values).to eq ["before_exec(#{aspect_class})", 'exec-result']
      end
    end
  end
end
