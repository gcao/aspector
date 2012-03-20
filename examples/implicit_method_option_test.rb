class A
  def test
    puts 'test'
  end
end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class ImplicitMethodOptionTest < Aspector::Base
  # Apply advice to options[:method] and options[:methods] if no target method is given
  # before options[:method], options[:methods] do
  before do
    puts 'before'
  end
end

# ImplicitMethodOptionTest.apply A, :method => 'test'
ImplicitMethodOptionTest.apply "A#test"

##############################

A.new.test

# Expected output:
# before
# test

