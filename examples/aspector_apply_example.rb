class A
  def test
    puts 'test'
  end
end

##############################

require_relative '../lib/aspector'

aspect = Aspector do
  target do
    def do_this
      puts 'do_this'
    end
  end

  before :test, :do_this

  before :test do
    puts 'do_that'
  end
end

##############################

aspect.apply(A)

A.new.test

# Expected output:
# do_this
# do_that
# test
