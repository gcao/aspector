$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'ruby-prof'
require 'aspector'

# Will print results in the way we want
def print_result(result, description)
  printer = RubyProf::FlatPrinter.new(result)
  print "#{'-' * 50} #{description}\n"
  printer.print(STDOUT)
end

ITERATIONS = 20_000
# We disable GC so it won't mess with our benchmarking
# Don't do this in production
GC.disable
