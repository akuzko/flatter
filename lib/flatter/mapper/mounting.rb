module Flatter
  module Mapper::Mounting
    extend ActiveSupport::Concern

    module FactoryMethods
      def create(mapper)
        super.tap do |mounting|
          mounting.mounter = mapper
          mounting.name = name
        end
      end
    end

    included do
      class_attribute :label
    end

    module ClassMethods
      def mount(name, **opts)
        factory_options = opts.reverse_merge(mounter_name: self.name || label)
        mountings[name.to_s] = Flatter::Mapper::Factory.new(name, **factory_options)
      end

      def mountings
        @mountings ||= {}
      end

      def mountings=(val)
        @mountings = val
      end
    end

    attr_accessor :mounter, :name

    def full_name
      [mounter.try(:name), name].compact.join('_')
    end

    def mappings
      super.tap do |mappings|
        inner_mountings.each do |mounting|
          mounting.local_mappings.each do |mapping|
            mappings.merge!(mapping.name => mapping, &merging_proc)
          end
        end
      end
    end

    def mapping_names
      super + local_mountings.map(&:mapping_names).flatten
    end

    def read
      local_mountings.map(&:read).inject(super, :merge)
    end

    def write(params)
      super
      local_mountings.each{ |mapper| mapper.write(params) }
      @_inner_mountings = nil
    end

    def root
      mounter.nil? ? self : mounter.root
    end

    def local_mountings
      class_mountings_for(self.class)
    end
    protected :local_mountings

    def class_mountings_for(klass)
      class_mountings(klass).map{ |factory| factory.create(self) }
    end
    private :class_mountings_for

    def class_mountings(klass)
      klass.mountings.values
    end
    private :class_mountings

    def mountings
      @mountings ||= inner_mountings.inject({}) do |res, mapper|
        res.merge(mapper.full_name => mapper, &merging_proc)
      end
    end

    def mounting_names
      local_mounting_names + local_mountings.map(&:mounting_names).flatten
    end

    def local_mounting_names
      local_mountings.map(&:name)
    end
    private :local_mounting_names

    def inner_mountings
      @_inner_mountings ||= local_mountings.map{ |mount| mount.as_inner_mountings }.flatten
    end
    protected :inner_mountings

    def as_inner_mountings
      [self, inner_mountings]
    end
    protected :as_inner_mountings

    def merging_proc
      proc { |_, old, new| Array(old).push(new) }
    end
    private :merging_proc
  end
end
