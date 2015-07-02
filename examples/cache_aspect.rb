$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aspector'

# Example class to which we will apply our aspects
class ExampleClass
  def test
    puts 'test'
    1
  end

  def test2
    puts 'test2'
    2
  end
end

# A simple cache engine
class SimpleCache
  @data = {}

  def self.cache(key, ttl)
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

# Aspect used to wrap methods with caching logic
class CacheAspect < Aspector::Base
  default ttl: 60

  around aspect_arg: true, method_arg: true do |aspect, method, proxy, &block|
    key = method
    ttl = aspect.options[:ttl]

    SimpleCache.cache key, ttl do
      proxy.call(&block)
    end
  end
end

CacheAspect.apply ExampleClass, method: :test, ttl: 2
CacheAspect.apply ExampleClass, method: :test2

instance = ExampleClass.new

# Will store value in cache
instance.test
instance.test2

# Will get value from cache
instance.test
instance.test2

sleep 3

instance.test  # Cache expired
instance.test2 # Cache is still valid
