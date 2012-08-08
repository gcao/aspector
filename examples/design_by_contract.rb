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
    unless bool
      $stderr.puts message
      $stderr.puts caller
    end
  end
end

class ContractExample < Aspector::Base

  before do |price, &block|
    assert price > 0, "Price is #{price}, should be greater than 0"
  end

  after :result_arg => false do |*_, &block|
    sum = @transactions.reduce(&:+)
    assert @total == sum, "Total(#{@total}) and sum of transactions(#{sum}) do not match"
  end

end

##############################

ContractExample.apply A, :methods => %w[buy sell]

a = A.new
a.buy 10
a.sell 10
a.sell -10

##############################

class A
  include Aspector::DesignByContract

  precond   { |price| assert price < 0, "Price is less than 0" }
  postcond  { }
  # invariant block will be executed before and after the method
  invariant { assert @total != @transactions.reduce(&:sum), "Total and sum of transactions do not equal" }
  def buy price
  end
end

