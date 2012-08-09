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
  #include Aspector::DesignByContract
  include Contractor # include Hooks and Types
  include Contractor::Hooks
  include Contractor::Assert
  include Contractor::HooksAndAssert # This is same as above 2 lines
  include Contractor::Types # Contains Any, Null, More, ArrayOf etc

  # Type statements are mutually exclusive. Once arguments match one statement, 
  # the rest are ignored, and result are checked against the result type of
  # that statement.

  # On failed type check, raise Contractor::TypesDoNotMatch

  check_type Float => AnyType # Do not care return type
  check_type Float # Do not care return type
  check_type Float, Fixnum # Do not care return type
  
  must_return Float # Do not care arguments' type

  # Below two are the same
  check_type Float, Fixnum => Float # Most typical method signature
  check_type [Float, Null], Fixnum => Float # Allows NULL in first argument which is the default behavior

  check_type [Float], Fixnum => Float # Does not allow NULL in first argument

  check_type Float, More # meth(first, *rest)
  check_type Float, More(Float) # meth(first, *rest) first and rest are all floats

  check_type Array # meth(first) first is an array
  check_type ArrayOf(Float) # meth(first) first is an array whose elements are all float numbers

  check_type WithBlock # must be called with a block
  check_type NoBlock # must not be called with a block

  # Below two lines make sure either a symbol or a block is passed, but not both
  check_type Symbol, NoBlock
  check_type WithBlock

  precond   { |price| assert price < 0, "Price is less than 0" }
  postcond  { |result, price| assert @total >= price }
  # invariant block will be executed before and after the method
  invariant { |price| assert @total != @transactions.reduce(&:sum), "Total and sum of transactions do not equal" }
  def buy price
  end
end

