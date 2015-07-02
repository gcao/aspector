require 'logger'

%w(
  version
  logging
  logger
  object_extension
  module_extension
  advice
  advice_metadata
  base
  base_class_methods
  method_matcher
  deferred_logic
  deferred_option
  aspect_instances
).each { |scope| require "aspector/#{scope}" }
