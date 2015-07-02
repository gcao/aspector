$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aspector'

# Class that fakes the ActiveRecord class
class ARClass
  def initialize
  end

  def save
  end
end

# Our ActiveRecord hooks aspect
class ActiveRecordHooks < Aspector::Base
  default private_methods: true

  before :initialize do
    puts "Before creating #{self.class.name} instance"
  end

  before :save do
    puts "Before saving #{self.class.name} instance"
  end
end

ActiveRecordHooks.apply(ARClass)

ar = ARClass.new
ar.save
