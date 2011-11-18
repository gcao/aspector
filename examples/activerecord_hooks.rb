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
  aspect = self

  default :private_methods => true

  before :initialize do
    puts "#{aspect}: before creating #{self.class.name} instance"
  end

  before :save do
    puts "#{aspect}: before saving"
  end
end

ActiveRecordHooks.apply(A)

##############################

a = A.new
a.save

