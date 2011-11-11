$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class A
  def test
    puts 'test'
  end
end

##############################

TestAspect = Aspector do
  target "
    def do_this
      puts 'do_this'
    end
  "

  before :test, :do_this
  before :test do
    puts 'do_that'
  end
end

TestAspect.apply(A)

##############################

A.new.test

# Expected output:
# do_this
# do_that
# test
