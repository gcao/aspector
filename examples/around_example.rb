$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class A
  def test
    puts 'test'
  end
end

##############################

aspector(A) do
  target "
    def do_this &block
      puts 'before'
      block.call
      puts 'after'
    end
  "

  around :test, :do_this
  around :test do |&block|
    puts 'before(block)'
    block.call
    puts 'after(block)'
  end
end

##############################

A.new.test

# Expected output:
# before(block)
# before
# test
# after
# after(block)
