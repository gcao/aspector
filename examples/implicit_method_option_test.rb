$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aspector'

# Example class to which we will apply our aspects
class ExampleClass
  def test
    puts 'test'
  end
end

# Aspect that we want to use
class ImplicitMethodOptionTest < Aspector::Base
  # Apply advice to options[:method] and options[:methods] if no target method is given
  # before options[:method], options[:methods] do
  before do
    puts 'before'
  end
end

ImplicitMethodOptionTest.apply(ExampleClass, method: :test)

ExampleClass.new.test
