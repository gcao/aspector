$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class A

  def test
    puts 'test'
  end

  def do_this &block
    puts 'before'
    block.call
    puts 'after'
  end

end

aspector(A) do
  around :test, :do_this
  #around(:test) do |&block|
  #  puts 'before(block)'
  #  block.call
  #  puts 'after(block)'
  #end
end

A.new.test
