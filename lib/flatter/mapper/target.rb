module Flatter
  module Mapper::Target
    class NoTargetError < ArgumentError
      def initialize(mapper_class)
        super("Target object is required to initialize #{mapper_class.name}")
      end
    end

    module FactoryMethods
      def fetch_target_from(mapper)
        return super unless options.key?(:target)

        target = options[:target]

        target.is_a?(Proc) ? target.(mapper.target) : target
      end
    end

    attr_reader :target

    def initialize(target, *, **)
      raise NoTargetError.new(self.class) unless target.present?

      super

      @target = target
    end

    def set_target(target)
      @target = target
    end

    def model_name
      target.class.model_name if target.class.respond_to?(:model_name)
    end
  end
end
