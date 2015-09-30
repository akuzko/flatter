module Flatter
  module Mapper::Traits
    extend ActiveSupport::Concern

    module FactoryMethods
      attr_accessor :extension

      def traits
        Array(options[:traits])
      end

      def trait?
        !!options[:trait]
      end

      def create(*)
        super.tap do |mounting|
          mounting.set_traits(traits)
          mounting.trait! if trait?
          mounting.extend_with(extension) if extension.present?
        end
      end

      def fetch_target_from(mapper)
        trait? ? mapper.target : super
      end
    end

    module ClassMethods
      def mount(*, &block)
        super.tap{ |f| f.extension = block }
      end

      def trait(name, &block)
        trait_name   = "#{name}_trait"
        mapper_class = Class.new(Flatter::Mapper, &block)

        if self.name.present?
          mapper_class_name = trait_name.camelize
          const_set(mapper_class_name, mapper_class)

          mount trait_name, mapper_class_name: "#{self.name}::#{mapper_class_name}", trait: true
        else
          mount trait_name, mapper_class: mapper_class, trait: true
        end
      end
    end

    def initialize(target, *traits, **, &block)
      super

      set_traits(traits)
      extend_with(block) if block.present?
    end

    def extend_with(extension)
      singleton_class.trait :extension, &extension
    end

    def set_target(target)
      if trait?
        mounter.set_target(target)
      else
        super
        trait_mountings.each{ |trait| trait.set_target!(target) }
      end
    end

    def set_target!(target)
      @target = target
    end
    protected :set_target!

    def full_name
      if name == 'extension_trait'
        super
      else
        name
      end
    end

    def local_mountings
      @local_mountings ||= class_mountings_for(singleton_class) + super
    end
    private :local_mountings

    def class_mountings(klass)
      mountings = super.reject do |factory|
        factory.trait? &&
          !(factory.name == 'extension_trait' || trait_names.include?(factory.name))
      end

      # For a given mountings list, it's trait factories are reordered according to
      # order of the trait names specified for a given object. for example, list
      # [m1, t1, m2, m3, t2, t3, m4] for traits list of [t2, t3, t1] will be
      # transformed to [m1, t2, m2, m3, t3, t1, m4]
      traits = trait_names.map{ |name| mountings.find{ |f| f.name == name } }.compact

      traits.
        map{ |t| mountings.index(t) }.
        sort.
        reverse.
        each_with_index{ |index, i| mountings[index] = traits[i] }

      mountings
    end
    private :class_mountings

    def traits
      @traits ||= []
    end

    def trait_names
      traits.map{ |trait| "#{trait.to_s}_trait" }
    end

    def set_traits(traits)
      @traits = traits
    end

    def trait?
      !!@trait
    end

    def trait!
      @trait = true
    end

    def trait_mountings
      @_trait_mountings ||= local_mountings.select(&:trait?)
    end
    private :trait_mountings

    def shared_methods
      self.class.public_instance_methods(false)
    end

    def respond_to_missing?(name, *)
      return false if trait?

      trait_mountings.any? do |trait|
        trait.shared_methods.include?(name)
      end
    end

    def method_missing(name, *args, &block)
      if trait?
        mounter.send(name, *args, &block)
      else
        trait = trait_mountings.detect{ |trait| trait.shared_methods.include?(name) }
        trait ? trait.send(name, *args, &block) : super
      end
    end
  end
end
