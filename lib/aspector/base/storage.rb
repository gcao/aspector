module Aspector
  class Base
    # Internal Base subclasses storage for storing any objects/informations
    # that we need to run Aspector
    # It was extracted from the Aspector::Base because we used to store a lot
    # of information there and by storing everything directly there, we've
    # added yet another responsibility to Aspector::Base class (and its subclasses)
    class Storage
      attr_accessor :advices
      attr_accessor :default_options
      attr_accessor :deferred_logics
      attr_reader :logger
      attr_reader :status

      # @param base [Aspector::Base] base class for which we create this storage - this accepts
      #   also any Aspector::Base descendant class
      # @note Note that we store stuff per class - not per instance (Aspector::Base.storage)
      # @example Create an storage instance for Aspector::Base class
      #   Aspector::Base::Storage.new(Aspector::Base) #=> storage instance
      def initialize(base)
        @base = base
        @advices = []
        @default_options = {}
        @deferred_logics = []
        @logger = Aspector::Logger.new(@base)
        @status = Aspector::Base::Status.new
      end
    end
  end
end
