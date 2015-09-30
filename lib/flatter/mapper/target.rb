module Flatter
  module Mapper::Target
    NoTargetError = Class.new(ArgumentError)

    module FactoryMethods
      def fetch_target_from(mapper)
        return super unless options.key?(:target)

        target = options[:target]

        case target
        when Proc then target.(mapper.target)
        when String, Symbol
          (mapper.private_methods + mapper.protected_methods + mapper.public_methods).include?(target.to_sym) ?
            mapper.send(target) :
            fail(ArgumentError, "Cannot use target #{target.inspect} with `#{mapper.name}`. Make sure #{target.inspect} is defined for #{mapper}")
        else target
        end
      end
    end

    attr_reader :target

    def initialize(target, *)
      unless target.present?
        fail NoTargetError, "Target object is required to initialize #{self.class.name}"
      end

      super

      @target = target
    end

    def set_target(target)
      @target = target
    end
  end
end
