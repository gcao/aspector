class A
  def test arg
    puts "test(#{arg}) 1"
    yield arg
    puts "test(#{arg}) 2"
  end
end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

aspector(A) do
  target do
    def do_this proxy, arg, &block
      puts "do_this(#{arg}) 1"
      proxy.call arg, &block
      puts "do_this(#{arg}) 2"
    end
  end

  around :test, :do_this

  around :test, :name => 'advice2' do |proxy, arg, &block|
    puts "advice2(#{arg}) 1"
    proxy.call arg, &block
    puts "advice2(#{arg}) 2"
  end
end

##############################

A.new.test 'x' do |arg|
  puts "block(#{arg})"
end

=begin EXPECTED OUTPUT

do_this(x) 1
advice2(x) 1
test(x) 1
block(x)
test(x) 2
advice2(x) 2
do_this(x) 2

=end

