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

    attr_accessor :factory

    def initialize(target = nil, *)
      super
      set_target!(target) if target.present?
    end

    def target
      ensure_target!
      @target
    end

    def ensure_target!
      initialize_target unless target_initialized?
    end
    protected :ensure_target!

    def initialize_target
      return set_target!(mounter.target) if trait?

      _mounter = mounter.trait? ? mounter.mounter : mounter
      set_target!(factory.fetch_target_from(_mounter))
    end
    private :initialize_target

    def set_target(target)
      if trait?
        mounter.set_target!(target)
      else
        set_target!(target)
        trait_mountings.each{ |trait| trait.set_target!(target) }
      end
    end

    def set_target!(target)
      fail NoTargetError, "Cannot set nil target for #{self.class.name}" if target.nil?
      @_target_initialized = true
      @target = target
    end

    def target_initialized?
      !!@_target_initialized
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
