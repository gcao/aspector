module Aspector
  class Helper
    class << self

      def handle_aspect context, *args, &block
        options = {}
        options = args.pop if args.last.is_a? Hash

        aspect = Aspector::Model::Aspect.new(options, &block)

        aspect.apply(context) if context.is_a? Module
        args.each {|target| aspect.apply(target) }

        aspect
      end

    end
  end
end
