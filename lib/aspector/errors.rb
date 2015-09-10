module Aspector
  # Module containing internal errors used in Aspector
  module Errors
    # Raised when we require a block of code but not provided
    class CodeBlockRequired < StandardError; end
    # Raised when we want to match item of a class that we dont support
    class UnsupportedItemClass < StandardError; end
    # Raised when we want to work with advice type that is not supported
    class InvalidAdviceType < StandardError; end
  end
end
