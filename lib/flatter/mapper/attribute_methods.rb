module Flatter
  module Mapper::AttributeMethods
    def respond_to_missing?(name, *)
      acceptable = mapping_names.map{ |name| [name, "#{name}="] }.flatten + mounting_names
      acceptable.map(&:to_sym).include?(name) || super
    end

    def method_missing(name, *args, &block)
      return super if @_attribute_methods_defined

      extend attribute_methods
      @_attribute_methods_defined = true

      send(name, *args, &block)
    end

    def attribute_methods
      accessor_names = mapping_names
      reader_names = mounting_names

      Module.new do
        reader_names.each do |name|
          define_method(name) do
            obj = mounting(name)
            obj.is_a?(Array) ? obj.map(&:read) : obj.read
          end
        end

        accessor_names.each do |name|
          define_method(name) do |*args|
            obj = mapping(name)
            obj.is_a?(Array) ?
              obj.map{ |mapping| mapping.read(*args) } :
              obj.read(*args)
          end

          define_method(:"#{name}=") do |value|
            fail RuntimeError, "Cannot directly write to a collection" if mapping(name).is_a?(Array)
            mapping(name).write(value)
          end
        end
      end
    end
    private :attribute_methods
  end
end
