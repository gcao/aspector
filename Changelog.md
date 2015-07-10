# Aspector

## Changelog

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
