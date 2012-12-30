class A
  def initialize
  end

  def save
  end
end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class ActiveRecordHooks < Aspector::Base
  logger.level = Aspector::Logging::TRACE

  default :private_methods => true

  before :initialize do
    puts "Before creating #{self.class.name} instance"
  end

  before :save do
    puts "Before saving #{self.class.name} instance"
  end
end

##############################

ActiveRecordHooks.apply(A)

a = A.new
a.save
