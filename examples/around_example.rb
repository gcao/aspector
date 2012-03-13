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
    def do_this &proxy
      puts 'before'
      proxy.call
      puts 'after'
    end
  end

  around :test, :do_this

  around :test do |&proxy|
    puts 'before(block)'
    proxy.call
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
