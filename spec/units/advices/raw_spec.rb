require 'spec_helper'

RSpec.describe 'Raw advices' do
  subject { klass.new }

  context 'standard case' do
    let(:klass) do
      ClassBuilder.build do
        def before_exec
          values << 'before_exec'
        end
      end
    end

    before do
      aspector(klass) do
        raw :exec do
          alias_method :exec_without_aspect, :exec

          def exec
            values << 'exec-result'
            exec_without_aspect
          end
        end
      end
    end

    it 'should execute exec_without_aspect' do
      expect(subject)
        .to receive(:exec_without_aspect)
        .once

      subject.exec
    end

    it 'should work' do
      subject.exec
      expect(subject.values).to eq %w( exec-result exec-result )
    end
  end

  context 'when we want to use method that is defined after aspector binding' do
    let(:klass) do
      ClassBuilder.build do
        aspector do
          raw :exec do
            alias_method :exec_without_aspect, :exec

            def exec
              after_defined_method
              exec_without_aspect
            end
          end
        end

        def after_defined_method
          values << 'after-defined'
        end
      end
    end

    it 'should be able to use it' do
      subject.exec
      expect(subject.values).to eq %w( after-defined exec-result )
    end
  end
end
