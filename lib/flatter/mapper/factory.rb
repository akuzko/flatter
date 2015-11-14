module Flatter
  class Mapper::Factory
    prepend Flatter::Mapper::Target::FactoryMethods
    prepend Flatter::Mapper::Mounting::FactoryMethods
    prepend Flatter::Mapper::Traits::FactoryMethods
    prepend Flatter::Mapper::Options::FactoryMethods
    prepend Flatter::Mapper::Collection::FactoryMethods

    NoTargetError = Class.new(RuntimeError)

    attr_reader :name, :options

    def initialize(name, **options)
      @name, @options = name.to_s, options
    end

    def mapper_class
      options[:mapper_class] || default_mapper_class
    end

    def default_mapper_class
      mapper_class_name.constantize
    rescue NameError => e
      Flatter.default_mapper_class or raise e
    end
    private :default_mapper_class

    def mapper_class_name
      options[:mapper_class_name] || modulize(default_mapper_class_name)
    end

    def default_mapper_class_name
      "#{name.camelize}Mapper"
    end

    def create(*)
      mapper_class.new.tap{ |mapper| mapper.factory = self }
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
      if mapper.target.respond_to?(name)
        mapper.target.public_send(name)
      else
        fail NoTargetError, "Unable to implicitly fetch target for '#{name}' from #{mapper}"
      end
    end
    private :default_target_from
  end
end
