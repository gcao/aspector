$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aspector'

# Example class to which we will apply our aspects
class ExampleClass
  def test
    puts 'test'
  end
end

aspector(ExampleClass) do
  before :test do
    puts 'do_before'
  end
end

aspector(ExampleClass) do
  after :test do |result|
    puts 'do_after'
    result
  end
end

ExampleClass.new.test
