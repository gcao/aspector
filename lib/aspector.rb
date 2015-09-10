%w(
  logger
  forwardable
  erb
  singleton
).each { |lib| require lib }

base_path = File.dirname(__FILE__) + '/aspector'

%w(
  refinements/class
  refinements/string
  errors
  version
  logging
  logger
  advice
  advice/method_matcher
  advice/metadata
  advice/params
  advice/builder
  interception
  interceptions_storage
  method_template
  base/class_methods
  base/dsl
  base/storage
  base/status
  base
  deferred/logic
  deferred/option
  extensions/module
  extensions/object
).each { |scope| require "#{base_path}/#{scope}" }
