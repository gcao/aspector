module Aspector
  module Extension

    def method_added_with_aspector method
      method_added_without_aspector(method)
    end

    def singleton_method_added_with_aspector method
      singleton_method_added_without_aspector(method)
    end

  end
end
