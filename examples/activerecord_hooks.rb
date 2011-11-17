class A

  def initialize
  end

  def save
  end

end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

ActiveRecordHooks = Aspector :private_methods => true do
  before :initialize do
    puts "Before creating #{self.class.name} instance"
  end

  before :save do
    puts "Before saving"
  end
end

ActiveRecordHooks.apply(A)

##############################

a = A.new
a.save

