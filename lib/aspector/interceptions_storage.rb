module Aspector
  # Storage for interceptions on an adviced class level
  # We need to store them on an aspected object in case we want to apply aspects on newly
  # defined (after the aspect applience) methods for objects
  # @note We should store here only interceptions that have existing_methods_only set to false/nil
  class InterceptionsStorage < Array
    # Applies all the interceptions to a given method
    # @param method [String] name of method to which we want to apply
    def apply_to_method(method)
      each do |interception|
        interception.apply_to_method method
      end
    end
  end
end
