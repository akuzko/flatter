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

    def read
      local_mountings.map(&:read).inject(super, :merge)
    end

    def write(params)
      super
      local_mountings.each{ |mapper| mapper.write(params) }
    end

    def local_mountings
      class_mountings_for(self.class)
    end
    private :local_mountings

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
      mountings.keys
    end

    def mounting(name)
      mountings[name.to_s]
    end

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
