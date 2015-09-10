require 'spec_helper'

RSpec.describe 'Around advices' do
  subject { klass.new }

  context 'standard case' do
    let(:klass) do
      ClassBuilder.build do
        def around_exec(proxy, &block)
          values << 'before-exec'
          result = proxy.call(&block)
          values << 'after-exec'
          result
        end
      end
    end

    before do
      aspector(klass) do
        around :exec, :around_exec
      end
    end

    it 'should wrap around the exec method and work' do
      subject.exec
      expect(subject.values).to eq %w( before-exec exec-result after-exec )
    end
  end

  context 'logic in string' do
    let(:klass) { ClassBuilder.build }

    before do
      aspector(klass) do
        around :exec, <<-CODE
          values << 'before-exec'
          result = INVOKE_PROXY
          values << 'after-exec'
          result
        CODE
      end
    end

    it 'should wrap around the exec method and work' do
      subject.exec
      expect(subject.values).to eq %w( before-exec exec-result after-exec )
    end
  end

  context 'logic in block' do
    let(:klass) { ClassBuilder.build }

    before do
      aspector(klass) do
        around :exec do |proxy, &block|
          values << 'before-exec'
          result = proxy.call(&block)
          values << 'after-exec'
          result
        end
      end
    end

    it 'should wrap around the exec method and work' do
      subject.exec
      expect(subject.values).to eq %w( before-exec exec-result after-exec )
    end
  end

  context 'when we want to use method that is defined after aspector binding' do
    let(:klass) do
      ClassBuilder.build do
        aspector do
          around :exec, :around_exec
        end

        def around_exec(proxy, &block)
          values << 'before-exec'
          result = proxy.call(&block)
          values << 'after-exec'
          result
        end
      end
    end

    it 'should be able to use it' do
      subject.exec
      expect(subject.values).to eq %w( before-exec exec-result after-exec )
    end
  end

  context 'method with parameters' do
    let(:klass) do
      ClassBuilder.build do
        def around_exec(method, proxy, *exec_params, &block)
          values << "before-exec(#{method})"
          result = proxy.call(&block)
          values << exec_params
          values << "after-exec(#{method})"
          values.flatten!
          result
        end
      end
    end

    let(:exec_param) { rand }

    before do
      aspector(klass) do
        around :exec, :around_exec, method_arg: true
      end
    end

    it 'should work' do
      subject.exec(exec_param)
      expected = (%w( before-exec(exec) exec-result ) << exec_param) + %w( after-exec(exec) )
      expect(subject.values).to eq expected
    end
  end

  context 'method with method_arg' do
    let(:klass) do
      ClassBuilder.build do
        def around_exec(method, proxy, &block)
          values << "before-exec(#{method})"
          result = proxy.call(&block)
          values << "after-exec(#{method})"
          result
        end
      end
    end

    before do
      aspector(klass) do
        around :exec, :around_exec, method_arg: true
      end
    end

    it 'should work' do
      subject.exec
      expect(subject.values).to eq %w( before-exec(exec) exec-result after-exec(exec) )
    end
  end

  context 'new result from aspect block' do
    let(:klass) { ClassBuilder.build }

    before do
      aspector(klass) do
        around :exec do |proxy, &block|
          values << 'before-exec'
          proxy.call(&block)
          values << 'after-exec'
          'block-result'
        end
      end
    end

    it 'should return them by default' do
      expect(subject.exec).to eq 'block-result'
      expect(subject.values).to eq %w( before-exec exec-result after-exec )
    end
  end

  describe 'implicit method option' do
    context 'when we want to bind to a single method' do
      let(:klass) do
        ClassBuilder.build do
          def around_method(proxy, &block)
            values << 'before-method'
            result = proxy.call(&block)
            values << 'after-method'
            result
          end
        end
      end

      before do
        aspector klass, method: %i( exec ) do
          around :around_method
        end
      end

      it 'should work' do
        subject.exec
        expect(subject.values).to eq %w( before-method exec-result after-method )
      end
    end

    context 'when we want to bind to multiple methods' do
      let(:klass) do
        ClassBuilder.build do
          def around_method(proxy, &block)
            values << 'before-method'
            result = proxy.call(&block)
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
          around :around_method
        end
      end

      it 'should work for method 1' do
        subject.exec
        expect(subject.values).to eq %w( before-method exec-result after-method )
      end

      it 'should work for method 2' do
        subject.exec_new
        expect(subject.values).to eq %w( before-method exec-new after-method )
      end
    end
  end

  context 'disabling aspect' do
    let(:klass) do
      ClassBuilder.build do
        def around_exec(proxy, &block)
          values << 'before-exec'
          result = proxy.call(&block)
          values << 'after-exec'
          result
        end
      end
    end

    let(:aspect) do
      aspector(klass) do
        around :exec, :around_exec
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
          expect(subject.values).to eq %w( exec-result before-exec exec-result after-exec )
        end
      end
    end
  end

  context 'disabling aspect' do
    let(:klass) do
      ClassBuilder.build do
        def around_exec(proxy, &block)
          values << 'before-exec'
          result = proxy.call(&block)
          values << 'after-exec'
          result
        end
      end
    end

    let(:aspect) do
      aspector(klass) do
        around :exec, :around_exec
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
    end

    context 'and we enable it back' do
      it 'should not work' do
        subject.exec
        expect(subject.values).to eq %w( exec-result )
        aspect.enable!
        subject.exec
        expect(subject.values).to eq %w( exec-result before-exec exec-result after-exec )
      end
    end
  end

  context 'all methods except' do
    let(:klass) do
      ClassBuilder.build do
        def around_exec(proxy, &block)
          values << 'before-exec'
          result = proxy.call(&block)
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
        around(/^ex.*/, :around_exec, except: :except_exec)
      end
    end

    it 'should work with exec' do
      subject.exec
      expect(subject.values).to eq %w( before-exec exec-result after-exec )
    end

    it 'should not work with except_exec' do
      subject.except_exec
      expect(subject.values).to eq %w( except-exec )
    end
  end
end
