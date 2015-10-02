# Aspector

[<img src="https://secure.travis-ci.org/gcao/aspector.png" />](http://travis-ci.org/gcao/aspector) [![Gem Version](https://badge.fury.io/rb/aspector.svg)](http://badge.fury.io/rb/aspector)

Aspector = ASPECT Oriented Ruby programming

## About

Aspector allows to use [aspect oriented programming](https://en.wikipedia.org/wiki/Aspect-oriented_programming) with Ruby.

Aspector allows adding additional behavior to existing code (an advice) without modifying the code itself, instead separately specifying which code is modified via a "pointcut" specification.

## Highlights

* Encapsulate logic as aspects and apply to multiple targets easily
* Support before/before_filter/after/around advices
* Work anywhere - inside/outside the target class, before/after methods are created
* Use regexp matching to apply advices to multiple methods
* Small codebase, intuitive API
* Conditional aspects disabling/enabling
* Standarized logging API
* Aspects are applicable to both classes/modules and instances
* Object extensions for easier usage

## Example usages

Aspector should be used whenever you have a cross-cutting concerns, especially when they don't perform any business logic. For example use can use it to provide things like:

* Logging
* Monitoring
* Performance benchmarking
* Any type of transactions wrapping
* Events producing for systems like Apache Kafka
* Etc...

## Installation

```bash
gem install aspector
```

or put it inside of your Gemfile:

```bash
gem 'aspector'
```

## Examples

To see how to use Aspector, please review examples that are in [examples directory](examples/).

If you need more detailed examples, please review files in [spec/functionals](spec/functionals) and [spec/units/advices](spec/units/advices).

Here's a simple example how Aspector can be used:

```ruby
class ExampleClass
  def test
    puts 'test'
  end
end

aspect = Aspector do
  target do
    def do_this
      puts 'do_this'
    end
  end

  before :test, :do_this

  before :test do
    puts 'do_that'
  end
end

aspect.apply(ExampleClass)
element = ExampleClass.new
element.test
aspect.disable!
element.test

# Expected output
# do_this
# do_that
# test
# test
```

## Configuration options

Aspector is really easy to use. After installation it doesn't require any additional configuration. You can however set two environments variables that are related to logging:

| ENV variable name  | Description                                                                          |
|--------------------|--------------------------------------------------------------------------------------|
| ASPECTOR_LOGGER    | Any logger class you want to use (if you don't want to use Aspector standard logger) |
| ASPECTOR_LOG_LEVEL | DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN                                        |

Aspector::Logger inherits from a [standard Ruby logger](http://ruby-doc.org/stdlib-2.2.0/libdoc/logger/rdoc/Logger.html). Log levels and the API are pretty standard. You can however use yor own:

```ruby
ASPECTOR_LOGGER='MyApp::Logger' ASPECTOR_LOG_LEVEL='any log level' ruby aspected_stuff.rb
```

## Default and apply options

Here are options that you can use when creating or applying a single aspect:

| Option name           | Type                                     | Description                                                                       |
|-----------------------|------------------------------------------|-----------------------------------------------------------------------------------|
| except                | Symbol, String, Regexp or Array of those | Will apply aspect to all the methods except those listed                          |
| name                  | String                                   | Advice name (really useful only for debugging)                                    |
| methods               | Array of Symbol, String, Regexp          | Method names (or regexp for matching) to which we should apply given aspect       |
| method                | Symbol, String, Regexp or Array of those | Acts as methods but accepts a single name of method (or a single regexp)          |
| existing_methods_only | Boolean (true/false) - default: false    | Will apply aspect only to already defined methods                                 |
| new_methods_only      | Boolean (true/false) - default: false    | Will apply aspect only to methods that were defined after aspect was applied      |
| private_methods       | Boolean (true/false) - default: false    | Should the aspect be applied to private methods as well (public only by default)  |
| class_methods         | Boolean (true/false) - default: false    | Should the aspect for instance methods of class methods of a given element        |
| method_arg            | Boolean (true/false) - default: false    | Do we want to have access to base method arguments in the aspect method/block     |
| interception_arg      | Boolean (true/false) - default: false    | Do we want to have access to the interception instance in the aspect method/block |

## Contributing to aspector

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add specs for it. This is important so I don't break it in a future version unintentionally.
* If it is a new functionality or feature please provide examples
* Please benchmark any functionality that might have a performance impact
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2015 Guoliang Cao, Maciej Mensfeld. See LICENSE.txt for further details.
