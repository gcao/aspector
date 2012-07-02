ENV["ASPECTOR_LOG_LEVEL"] ||= "warn"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rspec/autorun'
require 'aspector'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
end

def create_test_class &block
  klass = Class.new do
    def value
      @value ||= []
    end

    def test
      value << "test"
    end
  end

  klass.class_eval &block if block_given?
  klass
end

