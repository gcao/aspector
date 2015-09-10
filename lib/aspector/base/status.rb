module Aspector
  class Base
    # Object responsible for storing given aspect status
    # If aspect is enabled - its code will be executed after the aspect as applied
    # If aspect is disabled - its code won't be executed after the aspect is applied
    # @note This is stored on a class level (per aspect class)
    # @example Create a status and check it
    #   status = Aspector::Base::Status.new
    #   status.enabled? #=> true
    #   status.disable!
    #   status.enabled? #=> false
    #   status.enable!
    #   status.enabled? #=> true
    class Status
      # @return [Aspector::Base::Status] status instance
      # @note We're enabled by default
      def initialize
        @enabled = true
      end

      # Set status of an aspect to disabled
      # @example Set status to disabled
      #   status.disable!
      def disable!
        @enabled = false
      end

      # Set status of an aspect to enabled
      # @example Set status to enabled
      #   status.enable!
      def enable!
        @enabled = true
      end

      # Is the object for which we've created status object enabled?
      # @return [Boolean] Is this status object enabled (true if yes)
      # @example Check if we're enabled
      #   status.enabled? #=> true
      def enabled?
        @enabled == true
      end
    end
  end
end
