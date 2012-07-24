# Design by contract example

class A
  def initialize
    @transactions = []
    @total = 0
  end

  def buy price
    @transactions << price
    @total += price
  end

  def sell price
    @transactions << price # Wrong
    @total -= price
  end

end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class Object
  def assert bool, message = 'Assertion failure'
    $stderr.puts message unless bool
  end
end

class ContractExample < Aspector::Base

  before do |price, &block|
    assert price > 0, "Price is #{price}, should be greater than 0"
  end

  after do |*args, &block|
    sum = @transactions.reduce(&:+)
    assert @total == sum, "Total(#{@total}) and sum of transactions(#{sum}) do not match"
  end

end

##############################

ContractExample.apply A, :methods => %w[buy sell]

a = A.new
a.buy 10
a.buy -10
a.sell 10

