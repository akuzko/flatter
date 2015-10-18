module Flatter
  class Mapper::Factory
    prepend Flatter::Mapper::Target::FactoryMethods
    prepend Flatter::Mapper::Mounting::FactoryMethods
    prepend Flatter::Mapper::Traits::FactoryMethods
    prepend Flatter::Mapper::Options::FactoryMethods
    prepend Flatter::Mapper::Collection::FactoryMethods

    attr_reader :name, :options

    def initialize(name, **options)
      @name, @options = name.to_s, options
    end

    def mapper_class
      options[:mapper_class] || mapper_class_name.constantize
    end

    def mapper_class_name
      options[:mapper_class_name] || modulize(default_mapper_class_name)
    end

    def default_mapper_class_name
      "#{name.camelize}Mapper"
    end

    def create(mapper)
      mapper_class.new(fetch_target_from(mapper))
    end

    def modulize(class_name)
      if i = options[:mounter_name].rindex('::')
        "#{options[:mounter_name][0...i]}::#{class_name}"
      else
        class_name
      end
    end
    private :modulize

    def fetch_target_from(mapper)
      default_target_from(mapper)
    end

    def default_target_from(mapper)
      mapper.target.public_send(name) if mapper.target.respond_to?(name)
    end
    private :default_target_from
  end
end
