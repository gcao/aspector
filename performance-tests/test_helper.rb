$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'test/unit'
require 'ruby-prof/test'
require 'aspector'

RubyProf::Test::PROFILE_OPTIONS[:count     ] = 10000
RubyProf::Test::PROFILE_OPTIONS[:output_dir] = File.dirname(__FILE__) + "/output"
