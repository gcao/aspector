# This spec will execute all the examples to check if they are working
# By default all of them should work just fine
# Note that it won't check if the aspector works in examples as it should
# This is covered in unit and functional specs - here we check that all examples run
# without problems

require 'spec_helper'
require 'stringio'

# Kernel
module Kernel
  # Method used to catch the STDIO from all the examples
  # Examples by default print some stuff to the output - we don't want that
  # in our specs, thats why we catch it
  # We're only interested if all examples work as they should (without any errors)
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    out
  ensure
    $stdout = STDOUT
  end

  # Same as capture_stdout but to silence stderr
  def capture_stderr
    out = StringIO.new
    $stderr = out
    yield
    out
  ensure
    $stderr = STDOUT
  end
end

RSpec.describe 'Aspector benchmarks' do
  Dir.glob(
    File.join(
      File.dirname(__FILE__),
      '..',
      'benchmarks/**/*.rb'
    )
  ).each do |example_file|
    context "benchmark file: #{example_file}" do
      it 'should run without any errors' do
        capture_stdout do
          capture_stderr do
            Process.fork do
              require example_file
            end
          end
        end

        _pid, status = Process.wait2
        expect(status.exitstatus).to eq 0
      end
    end
  end
end
