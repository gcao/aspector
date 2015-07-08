$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aspector'

# Design by contract example class
class ExampleClass
  def initialize
    @transactions = []
    @total = 0
  end

  def buy(price)
    @transactions << price
    @total += price
  end

  def sell(price)
    @transactions << price # Wrong
    @total -= price
  end
end

# Object extensions
class Object
  def assert(bool, message = 'Assertion failure')
    return if bool

    $stderr.puts message
    $stderr.puts caller
  end
end

# Aspect that we will apply
class ContractExample < Aspector::Base
  before do |price, &_block|
    assert price > 0, "Price is #{price}, should be greater than 0"
  end

  after result_arg: false do |*_, &_block|
    sum = @transactions.reduce(&:+)
    assert @total == sum, "Total(#{@total}) and sum of transactions(#{sum}) do not match"
  end
end

ContractExample.apply ExampleClass, methods: %w( buy sell )

instance = ExampleClass.new
instance.buy(10)
instance.sell(10)
instance.sell(-10)
