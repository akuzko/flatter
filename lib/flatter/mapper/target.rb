module Flatter
  module Mapper::Target
    extend ActiveSupport::Concern

    NoTargetError = Class.new(ArgumentError)

    included do
      mapper_options << :target_class_name
    end

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
      if target.nil?
        fail NoTargetError, "Target object is required to initialize #{self.class.name}"
      end

      super

      @target = target
    end

    def set_target(target)
      fail NoTargetError, "Cannot set nil target for #{self.class.name}" if target.nil?
      @target = target
    end

    def target_class
      target_class_name.constantize
    end

    def target_class_name
      options[:target_class_name] || default_target_class_name
    end

    def default_target_class_name
      self.class.name.sub 'Mapper', ''
    end
  end
end
