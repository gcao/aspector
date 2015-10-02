module Aspector
  # Refinements that are used inside Aspector
  module Refinements
    # String refinements used inside Aspector
    module String
      # Regexp that is used to sanitize string, so it can be used as a instance variable name
      VARIABLE_REGEXP = %r{[?!=+\-\*/\^\|&\[\]<>%~]}

      refine ::String do
        # Converts a given string to a string that can be used as an instance variable
        # @return [String] converted string that can be used as an instance variable
        # @example Convert 'not a variable' to a variable string
        #   'not a variable'.to_instance_variable_name! #=> '@not_a_variable'
        def to_instance_variable_name!
          gsub! VARIABLE_REGEXP, '_'
          replace "@#{self}"
        end
      end
    end
  end
end
