$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class A

  def test
    puts 'test'
  end

  def do_this
    puts 'do_this'
  end

end

aspector(A) do
  before :test, :do_this
  before(:test) { puts 'do_that' }
end

A.new.test
