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

    module ClassMethods
      def mount(name, *args)
        mountings[name.to_s] = Flatter::Mapper::Factory.new(name, *args)
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
            mappings[mapping.name] = mapping
          end
        end
      end
    end

    def read
      inner_mountings.map(&:read).inject(super, :merge)
    end

    def write(params)
      super.tap do
        inner_mountings.each{ |mapper| mapper.write(params) }
      end
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
      @mountings ||= inner_mountings.each_with_object({}) do |mapper, res|
        res[mapper.full_name] = mapper
      end
    end

    def mounting(name)
      mountings[name.to_s]
    end

    def inner_mountings
      @_inner_mountings ||= local_mountings.map{ |mount| [mount, mount.inner_mountings] }.flatten
    end
    protected :inner_mountings
  end
end
