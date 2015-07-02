$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aspector'

# Example class to which we will apply our aspects
class ExampleClass
  def test(arg)
    puts "test(#{arg}) 1"
    yield arg
    puts "test(#{arg}) 2"
  end
end

aspector(ExampleClass) do
  target do
    def do_this(proxy, arg, &block)
      puts "do_this(#{arg}) 1"
      proxy.call arg, &block
      puts "do_this(#{arg}) 2"
    end
  end

  around :test, :do_this

  around :test, name: 'advice2' do |proxy, arg, &block|
    puts "advice2(#{arg}) 1"
    proxy.call arg, &block
    puts "advice2(#{arg}) 2"
  end
end

ExampleClass.new.test 'x' do |arg|
  puts "block(#{arg})"
end
