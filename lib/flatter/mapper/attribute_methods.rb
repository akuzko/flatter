module Flatter
  module Mapper::AttributeMethods
    def respond_to_missing?(name, *)
      acceptable = mapping_names.map{ |name| [name, "#{name}="] }.flatten + mounting_names
      acceptable.uniq.map(&:to_sym).include?(name) || super
    end

    def method_missing(name, *args, &block)
      return super if @_attribute_methods_defined

      extend attribute_methods
      @_attribute_methods_defined = true

      send(name, *args, &block)
    end

    def mounting(name)
      find_mounting(name.to_s)
    end

    def find_mounting(name)
      local_mountings.each do |mounting|
        if mounting.name == name || (mounting.pluralized? && mounting.name.pluralize == name)
          return mounting
        end
        nested = mounting.find_mounting(name)
        return nested if nested.present?
      end
      nil
    end
    protected :find_mounting

    def find_mounting_with(mapping_name)
      mapping_name = mapping_name.to_s

      match = local_mappings.any? do |mapping|
        if collection? || pluralized?
          mapping.name.pluralize == mapping_name
        else
          mapping.name == mapping_name
        end
      end

      return self if match

      local_mountings.each do |mounting|
        nested = mounting.find_mounting_with(mapping_name)
        return nested if nested.present?
      end

      nil
    end
    protected :find_mounting_with

    def attribute_methods
      _mapping_names = mapping_names
      _mounting_names = mounting_names - _mapping_names

      Module.new do
        _mounting_names.each do |name|
          define_method(name) do
            mount = find_mounting(name)
            if mount.collection?
              mount.read[name.to_s]
            elsif mount.pluralized?
              Array(mountings[mount.name]).map(&:read)
            else
              mount.read
            end
          end
        end

        _mapping_names.each do |name|
          define_method(name) do |*args|
            mount = find_mounting_with(name)
            if mount.collection? || mount.pluralized?
              Array(mapping(name.singularize)).map{ |map| map.read(*args) }
            else
              mapping(name).read(*args)
            end
          end

          define_method("#{name}=") do |value|
            mount = find_mounting_with(name)
            if mount.collection? || mount.pluralized?
              fail RuntimeError, "Cannot directly write to a collection"
            end
            mapping(name).write(value)
          end
        end
      end
    end
    private :attribute_methods
  end
end
