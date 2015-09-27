module Flatter
  module Mapper::Mapping
    extend ActiveSupport::Concern

    module ClassMethods
      def map(*args, **opts)
        mappings            = opts.slice!(*mapping_options)
        mappings_from_array = Hash[*args.zip(args).flatten]
        mappings.merge!(mappings_from_array)

        define_mappings(mappings, opts)
      end

      def define_mappings(mappings, options)
        mappings.each do |name, target_attribute|
          self.mappings[name.to_s] =
            Flatter::Mapping::Factory.new(name, target_attribute, options)
        end
      end
      private :define_mappings

      def mapping_options
        @@mapping_options ||= []
      end

      def mappings
        @mappings ||= {}
      end

      def mappings=(val)
        @mappings = val
      end
    end

    def read
      local_mappings.map(&:read_as_params).inject({}, :merge)
    end

    def write(params)
      params = params.with_indifferent_access
      local_mappings.each{ |mapping| mapping.write_from_params(params) }

      params
    end

    def local_mappings
      @_local_mappings ||= self.class.mappings.values.map{ |factory| factory.create(self) }
    end

    def mappings
      local_mappings.each_with_object({}) do |mapping, res|
        res[mapping.name] = mapping
      end
    end

    def mapping_names
      @_mapping_names ||= mappings.keys
    end

    def [](name)
      mappings[name.to_s].try(:read)
    end

    def []=(name, value)
      mappings[name.to_s].try(:write, value)
    end

    def mapping(name)
      mappings[name.to_s]
    end
  end
end
