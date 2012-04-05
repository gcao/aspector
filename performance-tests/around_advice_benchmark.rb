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
  around :test do |proxy, *args, &block|
    begin
      proxy.call *args, &block
    rescue => e
    end
  end
end

class RawAspect < Aspector::Base
  raw :test do |method,|
    eval <<-CODE
    alias #{method}_without_aspect #{method}

    def #{method} *args, &block
      #{method}_without_aspect *args, &block
    rescue => e
    end
    CODE
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

