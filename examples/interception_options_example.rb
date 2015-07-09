$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aspector'

# This example shows how can we access and use interception options
# Interception options are all the options that come from the default
# aspect options and directly from aspect applying
# Note that if you apply aspect instance to the same elements and
# you don't change options - they will be the same for all the classes/instances
# to which you apply this aspect. If you change apply parameters - the interception
# parameters will differ as well.

# Example class to which we will apply our aspects
class Example1Class
  def exec
    puts "#{Example1Class} exec execution"
  end
end

# Example class2 to which we will apply our aspects
class Example2Class
  def exec_different
    puts "#{Example2Class} exec_different execution"
  end
end

# Aspect used to wrap methods from example classes
class ExampleAspect < Aspector::Base
  default super_option: 60, key_option: 2

  around interception_arg: true, method_arg: true do |interception, method, proxy, &block|
    # Here we fetch options from both - interception and aspect class
    # Aspect options are transfered directly to all the instances of an aspect and to all
    # the interceptions. However they have a lower priority then interception direct options
    # so they can be overwritten by them
    method = interception.options[:method]
    key_option = interception.options[:key_option]
    super_option = interception.options[:super_option]
    interception_option = interception.options[:interception_option]

    puts "super_option value: #{super_option}"
    puts "key_option value: #{key_option}"

    proxy.call(&block)

    puts "interception_option value: #{interception_option}"
    puts "method value: #{method}"
  end
end

ExampleAspect.apply Example1Class, method: :exec, interception_option: 2
ExampleAspect.apply Example2Class, method: :exec_different

instance1 = Example1Class.new
instance2 = Example2Class.new

instance1.exec
instance2.exec_different

# --- instance1
# Expected output
# super_option value: 60
# key_option value: 2
# Example1Class exec execution
# interception_option value: 2
# method value: exec
# --- instance2
# super_option value: 60
# key_option value: 2
# Example2Class exec_different execution
# interception_option value:
# method value: exec_different
