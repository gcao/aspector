# Aspector

## Changelog

### 0.14.1

* Code structure refactoring
* Ruby 2.0 branch drop (no refinements)
* Full YARD documentation
* Code cleanup
* Changelog.md to CHANGELOG.md
* Deferred namespace for deferred elements (options and logic)
* Method matcher refactoring
* MethodMatcher is now used only internally in the Aspector::Advice space, so it was renamed to Aspector::Advice::MethodMatcher and it is now a part of the Aspector::Advice namespace
* Multiple Boolean like methods now fully Boolean (no more nils returned)
* Few naming convention tweaks
* Logging class refactoring
* Advice name now refers to its object_id not
* Extracted storing deferred logic and other options inside Aspector::Base::Storage to remove one of the base class responsibilities
* Changed enable to enable! and disable to disable! for enabling/disabling aspects
* Changed disabled? to positive enabled? By default aspect is enabled
* Extracted aspect activity status to Aspector::Base::Status to manage if a given aspect should be applied or not
* Forwardable for Aspect::Interception to cleanup the internal API
* Refinements for String (casting string into an instance variable name)
* Refinements for Class (detecting instance method type: private/protected/public)
* More specs
* Separated whole DSL logic into Aspector::Base::Dsl module
* Moved metadata to an Advice namespace (Aspector::Advice::Metadata)
* Moved Aspector::Advice _create_aspect_ into an Aspector::Advice::Builder to separate parameter formatting and building logic
* Separated general Ruby injected code into ::Module and ::Object extensions
* Moved base class methods into Aspector::Base::ClassMethods
* Extracted internal errors into Aspector::Errors module
* Removed Aspector::Advice#to_s - never used (not even for DEBUG logging)
* Moved Advice::Metadata fetching from dsl into Metadata class level (Metadata#before etc)
* Advice no longer accepts MethodMatcher in the initializer - instead it accepts array with methods that we want to match and builds matcher internally - that way we have a single matcher building (it happens in one place)
* Renamed the aop_ method prefix to aspector_advice_ - it seems more natural and easier for debug
* When creating advice (Advice.new) it now validates that either match_methods or block is provided
* When creating advice (Advice.new) it now validates that we want to build advice of a supported type
* Added instance usage example to examples/
* Added multiple aspects for the same element examples
* Aspector::Advice::Params for working with dynamic params on aspects creating
* Fixed misguiding naming on AspectInstances and renamed to InterceptionStorage
* Fixed aspect_instances to interceptions_storage
* Added benchmarks to spec suit to ensure that they pass after each change
* Moved method template to a separate file to clean the interception
* Added Rubocop to the whole project except interception.rb and object.rb
* Rubocop remarks
* Added memory and performance benchmarks based on the base benchmarks
* Refactoring of module.rb to extract common parts to a single method
* Renamed aop_ prefix to aspector_ so when we do private_methods on a module it will be more precise what to those methods are related
* Cleaned method accessibility - some public methods were used only in a private scope so they became private
* Improved interception storage usage - now only interceptions that are not set to existing_methods_only are stored (less memory used)

### 0.14.0

* Created instance of an aspect can be applied to multiple targets(classes/instances)
* aspect_arg replaced with interception_arg because of multiple possible targets with different options
* aspect_arg no longer works - accessing aspect can be done via interception (interception.aspect)
* Interception options inherit all the default aspect options + options per interception
* Specs for interception_arg
* Specs for accessing interception options
* Specs that validate if interception options inherit aspect default options
* Logger proc printing instead of evaluating fix
* jruby support drop - there's no 2.0 syntax for jruby yet. Once it's out of beta - no further work needs to be done (works for me on beta)
* drop 1.8 and 1.9 - even ruby guys recommend upgrading
* added rubocop for spec/, examples/ and benchmarks/
* fixed examples issues (they were not working anymore)
* fixed benchmarks (outdated libs, etc)
* added examples execution to rspec - now rspec will notify if any example is not working. That way we will be able to provide code changes without having to worry that they will break examples
* added way more specs (93% code coverage)
* added rubocop to travis
* some minor cleanups
* moved from rvmrc (deprecated) to ruby-gemset and ruby-version
* removed unused gems
* added simplecov to track code coverage
* updated syntax to match 2.2.2
* moved versioning to Aspector::VERSION
* gemspec cleanup
* benchmarks now use RubyProf new version
* benchmarks moved to /benchmarks
* all the examples work again
* lib/aspector load order rearrange
* aspector advice rearrange - now it doesn't have to use integer values with constants
* before_filter as a separate TYPE - that way we don't have to "if" anything - works out of the box easier
* some method optimization or rewrites for many methods - works the same, looks way better
* advices metadata cleanup - no need for mandatory_options anymore
* API CHANGE: old_methods_only replaced with existing_methods_only - when I started to use aspector the "old" was hard to understand - existing is way more straightforward
* base disabled? now returns either true or false (no nil since it might change)
* boolean methods that return nil return now true/false
* before advices are now picked from before and before_filter advices
* METHOD_TEMPLATE update with new logger logic
* METHOD_TEMPLATE indentations are now more readable
* base_class_methods now generate all the bind methods automatically based on Aspector::Advice::TYPES
* deferred options to_s cleanup
* New logger that is based on Ruby default logger (::Logger) - same log levels, same API (except *args for our contextes)
* Logger is now much smaller
* Logging - constanize is now easier to read but the API stays the same (fallback as well)
* Method matcher#to_s uses now the & syntax for inspect
* ObjectExtension #returns removed - it was never used (throw was never used)
* Spec helper cleanup
* Rspec no longer needs monkey patching (config.disable_monkey_patching!)
* Class building logic is now wrapped in a module instead of a single method - all the class "building" and "cloning" happens in one place
* Added some pendings for future improvement
* skip_if_false for a before that should act as before_filter removed (since before filter is now a separate aspect)
* version dump
