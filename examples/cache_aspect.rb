class A

  def test
    puts 'test'
    1
  end

  def test2
    puts 'test2'
    2
  end

end

##############################

class SimpleCache

  @data = {}

  def self.cache key, ttl
    found = @data[key]  # found is like [time, value]

    if found
      puts "Found in cache: #{key}"
      insertion_time, value = *found

      return value if Time.now < insertion_time + ttl

      puts "Expired: #{key}"
    end

    value = yield
    @data[key] = [Time.now, value]
    value
  end

end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class CacheAspect < Aspector::Base
  default :ttl => 60

  around options[:method], :context_arg => true do |context, &block|
    key = context.method_name
    ttl = context.options[:ttl]

    SimpleCache.cache key, ttl do
      block.call
    end
  end

end

##############################

CacheAspect.apply A, :method => :test, :ttl => 2  # 2 seconds
CacheAspect.apply A, :method => :test2

a = A.new

# Will store value in cache
a.test
a.test2

# Will get value from cache
a.test
a.test2

sleep 3

a.test  # Cache expired
a.test2 # Cache is still valid

