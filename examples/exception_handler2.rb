class A

  def self.test input
    puts input.upcase
  end

  def test input
    puts input.upcase
  end

end

##############################

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'aspector'

class ExceptionHandler < Aspector::Base

  module ToBeIncluded
    def handle_exception proxy, *args, &block
      proxy.call *args, &block
    rescue => e
      puts "Rescued: #{e}"
    end
  end

  around :handle_exception

end

##############################

ExceptionHandler.apply A, :method => "test", :class_methods => true

A.test 'good'
A.test nil

ExceptionHandler.apply A, :method => "test"

a = A.new
a.test 'good'
a.test nil

