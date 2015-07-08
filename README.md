# Aspector

[<img src="https://secure.travis-ci.org/gcao/aspector.png" />](http://travis-ci.org/gcao/aspector)

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
aspect.disable
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

Aspector::Logger inherits from a [standard Ruby logger](ruby-doc.org/stdlib-2.2.0/libdoc/logger/rdoc/Logger.html). Log levels and the API are pretty standard. You can however use yor own:

```ruby
ASPECTOR_LOGGER='MyApp::Logger' ASPECTOR_LOG_LEVEL='any log level' ruby aspected_stuff.rb
```

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
