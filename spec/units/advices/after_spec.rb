require 'spec_helper'

RSpec.describe 'After advices' do
  subject { klass.new }

  context 'standard case' do
    let(:klass) do
      ClassBuilder.build do
        def after_exec(result)
          values << 'after-exec'
          result
        end
      end
    end

    before do
      aspector(klass) do
        after :exec, :after_exec
      end
    end

    it 'should execute after_exec' do
      expect(subject)
        .to receive(:after_exec)
        .once

      subject.exec
    end

    it 'should work' do
      subject.exec
      expect(subject.values).to eq %w( exec-result after-exec )
    end
  end

  context 'logic in string' do
    let(:klass) { ClassBuilder.build }

    before do
      aspector(klass) do
        after :exec, <<-CODE
          values << 'after-exec'
          result
        CODE
      end
    end

    it 'should work' do
      subject.exec
      expect(subject.values).to eq %w( exec-result after-exec )
    end
  end

  context 'logic in block' do
    let(:klass) { ClassBuilder.build }

    before do
      aspector(klass) do
        after :exec do |result|
          values << 'after_value'
          result
        end
      end
    end

    it 'should work' do
      subject.exec
      expect(subject.values).to eq %w( exec-result after_value )
    end
  end

  context 'when we want to use method that is defined after aspector binding' do
    let(:klass) do
      ClassBuilder.build do
        aspector do
          after :exec, :after_exec
        end

        def after_exec(result)
          values << 'after-exec'
          result
        end
      end
    end

    it 'should be able to use it' do
      subject.exec
      expect(subject.values).to eq %w( exec-result after-exec )
    end
  end

  context 'method with parameters' do
    let(:klass) do
      ClassBuilder.build do
        def after_exec(method, result, *exec_params)
          values << "after-exec(#{method})"
          values << exec_params
          values.flatten!
          result
        end
      end
    end

    let(:exec_param) { rand }

    before do
      aspector(klass) do
        after :exec, :after_exec, method_arg: true
      end
    end

    it 'should execute after_exec with method args' do
      expect(subject)
        .to receive(:after_exec)
        .with('exec', ['exec-result'], exec_param)
        .once

      subject.exec(exec_param)
    end

    it 'should work' do
      subject.exec(exec_param)
      expect(subject.values).to eq %w( exec-result after-exec(exec) ) << exec_param
    end
  end

  context 'method with method_arg' do
    let(:klass) do
      ClassBuilder.build do
        def after_exec(method, result)
          values << "after_exec(#{method})"
          result
        end
      end
    end

    before do
      aspector(klass) do
        after :exec, :after_exec, method_arg: true
      end
    end

    it 'should execute after_exec with method args' do
      expect(subject)
        .to receive(:after_exec)
        .with('exec', ['exec-result'])
        .once

      subject.exec
    end

    it 'should work' do
      subject.exec
      expect(subject.values).to eq %w( exec-result after_exec(exec) )
    end
  end

  context 'new result from aspect block' do
    let(:klass) { ClassBuilder.build }

    before do
      aspector(klass) do
        after :exec do |_result|
          values << 'after_value'
          'block-result'
        end
      end
    end

    it 'should return it by default' do
      expect(subject.exec).to eq 'block-result'
      expect(subject.values).to eq %w( exec-result after_value )
    end
  end

  context 'when result_arg is set to false' do
    let(:klass) do
      ClassBuilder.build do
        def exec
          values << 'exec-result'
          'exec-result'
        end
      end
    end

    before do
      aspector(klass) do
        after :exec, result_arg: false do
          values << 'do_after'
          'do_after'
        end
      end
    end

    it 'should return original method return value' do
      expect(subject.exec).to eq 'exec-result'
    end

    it 'should still execute the after block' do
      subject.exec
      expect(subject.values).to eq %w( exec-result do_after )
    end
  end

  describe 'implicit method option' do
    context 'when we want to bind to a single method' do
      let(:klass) do
        ClassBuilder.build do
          def after_method(result)
            values << 'after-method'
            result
          end
        end
      end

      before do
        aspector klass, method: %i( exec ) do
          after :after_method
        end
      end

      it 'should work' do
        subject.exec
        expect(subject.values).to eq %w( exec-result after-method )
      end
    end

    context 'when we want to bind to multiple methods' do
      let(:klass) do
        ClassBuilder.build do
          def after_method(result)
            values << 'after-method'
            result
          end

          def exec_new
            values << 'exec-new'
          end
        end
      end

      before do
        aspector klass, methods: %i( exec exec_new ) do
          after :after_method
        end
      end

      it 'should work for method 1' do
        subject.exec
        expect(subject.values).to eq %w( exec-result after-method )
      end

      it 'should work for method 2' do
        subject.exec_new
        expect(subject.values).to eq %w( exec-new after-method )
      end
    end
  end

  describe 'disabling aspect' do
    let(:klass) do
      ClassBuilder.build do
        def after_method(result)
          values << 'after-method'
          result
        end
      end
    end

    let(:aspect) do
      aspector klass, method: %i( exec ) do
        after :after_method
      end
    end

    before do
      aspect.disable!
    end

    context 'when we define an aspect and we disable it' do
      it 'should not work' do
        subject.exec
        expect(subject.values).to eq %w( exec-result )
      end

      context 'and we enable it back' do
        it 'should work again' do
          subject.exec
          expect(subject.values).to eq %w( exec-result )
          aspect.enable!
          subject.exec
          expect(subject.values).to eq %w( exec-result exec-result after-method )
        end
      end
    end
  end

  context 'all methods except' do
    let(:klass) do
      ClassBuilder.build do
        def after_exec(result)
          values << 'after-exec'
          result
        end

        def except_exec
          values << 'except-exec'
        end
      end
    end

    before do
      aspector(klass) do
        after(/^ex.*/, :after_exec, except: :except_exec)
      end
    end

    it 'should work with exec' do
      subject.exec
      expect(subject.values).to eq %w( exec-result after-exec )
    end

    it 'should not work with except_exec' do
      subject.except_exec
      expect(subject.values).to eq %w( except-exec )
    end
  end
end
