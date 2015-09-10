# Helper methods for benchmarking aspector using rubyprof
# To run a given benchmark file just use following command:
#   bundle exec benchmarks/given_file.rb
# Or if you want to benchmark something else than process time:
#  TYPE=memory bundle exec benchmarks/given_file.rb
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'ruby-prof'
require 'aspector'

ITERATIONS = 20_000
# We disable GC so it won't mess with our benchmarking
# Don't do this in production
GC.disable

# Types of benchmarks that we want to use
TYPES = {
  cpu: RubyProf::CPU_TIME,
  memory: RubyProf::MEMORY,
  time: RubyProf::PROCESS_TIME
}

# Current benchmarking type
TYPE = TYPES[(ENV['TYPE'] || 'cpu').to_sym] || TYPES[:time]

# Will print results in the way we want
def print_result(result, description)
  printer = RubyProf::FlatPrinter.new(result)
  print "#{'-' * 50} #{description}\n"
  printer.print($stdout)
end

# Benchmarks and prints results
# @param [String] benchmark description
# @yield Block of code that we want to benchmark
def benchmark(description)
  RubyProf.measure_mode = TYPE

  RubyProf.start
  ITERATIONS.times { yield }
  result = RubyProf.stop

  print_result(result, description)
end
