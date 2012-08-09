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

# Use TYPE_CHECK_LEVEL/ASSERT_LEVEL=none/info/warn/fail
# to enable/disable type check and pre/post conditions etc
# Make it possible to enable/disable for specific class/module
class A
  include Kontract # include Hooks and Types
  include Kontract::Hooks
  include Kontract::Assert
  include Kontract::HooksAndAssert # This is same as above 2 lines
  include Kontract::Types # Contains AnyType, Null, More, ArrayOf etc

  # define custom environment variable for enabling/disabling type checks
  checktype_env "A_CHECKTYPE"
  assertion_env "A_ASSERTION"

  # Type statements are mutually exclusive. Once arguments match one statement, 
  # the rest are ignored, and result are checked against the result type of
  # that statement.

  # On failed type check, raise Contractor::TypesDoNotMatch, or ArgumentError?

  checktype Float => AnyType # Do not care return type
  checktype Float # Do not care return type
  checktype Float, Fixnum # Do not care return type
  
  checktype Return(Float)

  checktype DuckType(:do_something) => Float
  checktype DuckType(Float){|arg| arg >= 0}

  # Below two are the same
  checktype Float, Fixnum => Float # Most typical method signature
  checktype [Float, Null], Fixnum => Float # Allows NULL in first argument which is the default behavior

  checktype [Float], Fixnum => Float # Does not allow NULL in first argument

  checktype Float, More # meth(first, *rest)
  checktype Float, More(Float) # meth(first, *rest) first and rest are all floats

  checktype Array # meth(first) first is an array
  checktype ArrayOf(Float) # meth(first) first is an array whose elements are all float numbers

  checktype WithBlock # must be called with a block
  checktype NoBlock # must not be called with a block

  checktype Float, NoBlock => Float

  # Below two lines make sure either a symbol or a block is passed, but not both
  checktype Symbol, NoBlock
  checktype WithBlock

  precond   { |price| assert price < 0, "Price is less than 0" }
  postcond  { |result, price| assert @total >= price }
  # invariant block will be executed before and after the method
  invariant { |price| assert @total != @transactions.reduce(&:sum), "Total and sum of transactions do not equal" }
  def buy price
  end
end

