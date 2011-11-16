class A
  def test
    puts 'test'
  end
end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

aspector(A) do
  target do
    def do_this &block
      puts 'before'
      block.call
      puts 'after'
    end
  end

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
# before
# before(block)
# test
# after(block)
# after
