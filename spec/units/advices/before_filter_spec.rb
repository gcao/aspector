require 'spec_helper'

RSpec.describe 'Before filter advices' do
  subject { klass.new }

  context 'standard cases' do
    before do
      aspector(klass) do
        before_filter :exec, :before_exec
      end
    end

    context 'when code returns false' do
      let(:klass) do
        ClassBuilder.build do
          def before_exec
            values << 'before_exec'
            false
          end
        end
      end

      it 'should execute before_exec' do
        expect(subject)
          .to receive(:before_exec)
          .once

        subject.exec
      end

      it 'should not execute original code' do
        subject.exec
        expect(subject.values).to eq %w( before_exec )
      end
    end

    context 'when code returns nil' do
      let(:klass) do
        ClassBuilder.build do
          def before_exec
            values << 'before_exec'
            nil
          end
        end
      end

      it 'should execute before_exec' do
        expect(subject)
          .to receive(:before_exec)
          .once

        subject.exec
      end

      it 'should not execute original code' do
        subject.exec
        expect(subject.values).to eq %w( before_exec )
      end
    end

    context 'when code doesnt return false or nil' do
      let(:klass) do
        ClassBuilder.build do
          def before_exec
            values << 'before_exec'
          end
        end
      end

      it 'should execute before_exec' do
        expect(subject)
          .to receive(:before_exec)
          .once

        subject.exec
      end

      it 'should work' do
        subject.exec
        expect(subject.values).to eq %w( before_exec exec-result )
      end
    end
  end

  context 'logic in string' do
    let(:klass) { ClassBuilder.build }

    before do
      aspector(klass) do
        before_filter :exec, <<-CODE
          values << 'before-exec'
        CODE
      end
    end

    it 'should work' do
      subject.exec
      expect(subject.values).to eq %w( before-exec exec-result )
    end
  end

  context 'logic in block' do
    let(:klass) { ClassBuilder.build }

    before do
      aspector(klass) do
        before_filter :exec do
          values << 'before-exec'
        end
      end
    end

    it 'should work' do
      subject.exec
      expect(subject.values).to eq %w( before-exec exec-result )
    end
  end

  context 'when we want to use method that is defined after aspector binding' do
    let(:klass) do
      ClassBuilder.build do
        aspector do
          before_filter :exec, :before_exec
        end

        def before_exec
          values << 'before-exec'
        end
      end
    end

    it 'should be able to use it' do
      subject.exec
      expect(subject.values).to eq %w( before-exec exec-result )
    end
  end

  context 'method with method_arg' do
    let(:klass) do
      ClassBuilder.build do
        def before_exec(method)
          values << "before_exec(#{method})"
        end
      end
    end

    before do
      aspector(klass) do
        before_filter :exec, :before_exec, method_arg: true
      end
    end

    it 'should execute before_exec with method args' do
      expect(subject)
        .to receive(:before_exec)
        .with('exec')
        .once

      subject.exec
    end

    it 'should work' do
      subject.exec
      expect(subject.values).to eq %w( before_exec(exec) exec-result )
    end
  end

  describe 'implicit method option' do
    context 'when we want to bind to a single method' do
      let(:klass) do
        ClassBuilder.build do
          def before_method
            values << 'before-method'
          end
        end
      end

      before do
        aspector klass, method: %i( exec ) do
          before_filter :before_method
        end
      end

      it 'should work' do
        subject.exec
        expect(subject.values).to eq %w( before-method exec-result )
      end
    end

    context 'when we want to bind to multiple methods' do
      let(:klass) do
        ClassBuilder.build do
          def before_method
            values << 'before-method'
          end

          def exec_new
            values << 'exec-new'
          end
        end
      end

      before do
        aspector klass, methods: %i( exec exec_new ) do
          before_filter :before_method
        end
      end

      it 'should work for method 1' do
        subject.exec
        expect(subject.values).to eq %w( before-method exec-result )
      end

      it 'should work for method 2' do
        subject.exec_new
        expect(subject.values).to eq %w( before-method exec-new )
      end
    end
  end

  context 'disabling aspect' do
    let(:klass) do
      ClassBuilder.build do
        def before_exec
          values << 'before-exec'
        end
      end
    end

    let(:aspect) do
      aspector(klass) do
        before_filter :exec, :before_exec
      end
    end

    before do
      aspect.disable
    end

    context 'when we define an aspect and we disable it' do
      it 'should not work' do
        subject.exec
        expect(subject.values).to eq %w( exec-result )
      end
    end

    context 'and we enable it back' do
      it 'should not work' do
        subject.exec
        expect(subject.values).to eq %w( exec-result )
        aspect.enable
        subject.exec
        expect(subject.values).to eq %w( exec-result before-exec exec-result )
      end
    end
  end

  context 'all methods except' do
    let(:klass) do
      ClassBuilder.build do
        def before_exec
          values << 'before-exec'
        end

        def except_exec
          values << 'except-exec'
        end
      end
    end

    before do
      aspector(klass) do
        before_filter(/^ex.*/, :before_exec, except: :except_exec)
      end
    end

    it 'should work with exec' do
      subject.exec
      expect(subject.values).to eq %w( before-exec exec-result )
    end

    it 'should not work with except_exec' do
      subject.except_exec
      expect(subject.values).to eq %w( except-exec )
    end
  end
end
