require 'logger'

base_path = File.dirname(__FILE__) + '/aspector'

%w(
  version
  logging
  logger
  object_extension
  module_extension
  advice
  advice_metadata
  interception
  base
  base_class_methods
  method_matcher
  deferred_logic
  deferred_option
  aspect_instances
).each { |scope| require "#{base_path}/#{scope}" }
