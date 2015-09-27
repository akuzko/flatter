module Flatter
  module Mapper::AttributeMethods
    def respond_to_missing?(name, *)
      mapping_names.map{ |name| [name, :"#{name}="] }.flatten.include?(name) || super
    end

    def method_missing(name, *args, &block)
      return super if @_attribute_methods_defined

      extend attribute_methods
      @_attribute_methods_defined = true

      send(name, *args, &block)
    end

    def attribute_methods
      names = mapping_names
      Module.new do
        names.each do |name|
          define_method(name){ |*args| mapping(name).read(*args) }

          define_method(:"#{name}="){ |value| mapping(name).write(value) }
        end
      end
    end
    private :attribute_methods
  end
end
