module Flatter
  class Mapper::Factory
    prepend Flatter::Mapper::Target::FactoryMethods
    prepend Flatter::Mapper::Mounting::FactoryMethods
    prepend Flatter::Mapper::Traits::FactoryMethods

    attr_reader :name, :options

    def initialize(name, **options)
      @name, @options = name.to_s, options
    end

    def mapper_class
      options[:mapper_class] || mapper_class_name.constantize
    end

    def mapper_class_name
      options[:mapper_class_name] || "#{name.to_s.camelize}Mapper"
    end

    def create(mapper)
      mapper_class.new(fetch_target_from(mapper)).tap do |mounting|
        mounting.name = name.to_s
      end
    end

    def fetch_target_from(mapper)
      mapper.target.public_send(name)
    end
  end
end
