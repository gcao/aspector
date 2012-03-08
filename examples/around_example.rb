class A
  def test
    puts 'test 1'
    yield
    puts 'test 2'
  end
end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

aspector(A) do
  target do
    def do_this proxy, &block
      puts 'before'
      proxy.call &block
      puts 'after'
    end
  end

  around :test, :do_this

  around :test do |proxy, &block|
    puts 'before(block)'
    proxy.call &block
    puts 'after(block)'
  end
end

##############################

A.new.test do
  puts 'in block'
end

# Expected output:
# before
# before(block)
# test
# after(block)
# after
