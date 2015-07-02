require 'spec_helper'

RSpec.describe 'Special chars in method names' do
  subject { klass.new }

  methods_postfixes = %w( ? ! = )
  full_methods = %w( + - * / ~ | % & ^ < > [] []= )

  context 'special characters in instance method names' do
    methods_postfixes.each do |char|
      context "when method name contains '#{char}'" do
        let(:klass) do
          ClassBuilder.build do
            aspector do
              before "exec#{char}", :exec
            end

            define_method "exec#{char}" do |*_args|
              values << char
            end
          end
        end

        it 'should handle it without any issues' do
          subject.send "exec#{char}"
          expect(subject.values).to eq ['exec-result', char]
        end
      end
    end

    full_methods.each do |char|
      context "when method name is '#{char}'" do
        let(:klass) do
          ClassBuilder.build do
            aspector do
              before char, :exec
            end

            define_method char do |*_args|
              values << char
            end
          end
        end

        it 'should handle it without any issues' do
          subject.send(char, 1)
          expect(subject.values).to eq ['exec-result', char]
        end
      end
    end
  end

  context 'special characters in class method names' do
    methods_postfixes.each do |char|
      context "when method name contains '#{char}'" do
        self.class.send :define_method, :methods_postfixes do
          methods_postfixes
        end

        let(:klass) do
          ClassBuilder.build do
            aspector class_methods: true do
              before "exec#{char}", :exec
            end

            class << self
              def values
                @values ||= []
              end

              def exec(*_args)
                values << 'exec-result'
              end

              methods_postfixes.each do |char|
                define_method "exec#{char}" do |*args|
                  values << args.first
                end
              end
            end
          end
        end

        it 'should handle it without any issues' do
          klass.send("exec#{char}", char)
          expect(klass.values).to eq ['exec-result', char]
        end
      end
    end

    full_methods.each do |char|
      context "when method name is '#{char}'" do
        self.class.send :define_method, :full_methods_names do
          full_methods
        end

        let(:klass) do
          ClassBuilder.build do
            aspector class_methods: true do
              before char, :exec
            end

            class << self
              def values
                @values ||= []
              end

              def exec(*_args)
                values << 'exec-result'
              end

              full_methods_names.each do |char|
                define_method char do |*args|
                  values << args.first
                end
              end
            end
          end
        end

        it 'should handle it without any issues' do
          klass.send(char, char)
          expect(klass.values).to eq ['exec-result', char]
        end
      end
    end
  end
end
