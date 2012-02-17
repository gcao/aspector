class A
  def test input
    input.upcase!
  end
end

class B
  def test input
    input.upcase!
  end
end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class AroundAspect < Aspector::Base
  target do
    def do_this *args, &block
      block.call *args, &block
    rescue => e
    end
  end

  around :test, :do_this
end

##############################

class RawAspect < Aspector::Base
  target do
    wrapped_method = instance_method(:test)
    define_method :test do |*args, &block|
      begin
        wrapped_method.bind(self).call *args, &block
      rescue => e
      end
    end
  end
end

##############################

AroundAspect.apply(A)
RawAspect.apply(B)

a = A.new
b = B.new

require 'benchmark'
TIMES = 100000
Benchmark.bmbm do |x|
  x.report "Around advice - good" do
    TIMES.times { a.test 'good' }
  end
  x.report "Around advice - bad" do
    TIMES.times { a.test nil }
  end
  x.report "Raw - good" do
    TIMES.times { b.test 'good' }
  end
  x.report "Raw - bad" do
    TIMES.times { b.test nil }
  end
end

