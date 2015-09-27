module Flatter
  class Mapping
    extend ActiveSupport::Autoload

    autoload :Factory
    autoload :Scribe

    attr_reader :mapper, :name, :target_attribute, :options

    delegate :target, to: :mapper

    def initialize(mapper, name, target_attribute, **options)
      @mapper           = mapper
      @name             = name.to_s
      @target_attribute = target_attribute
      @options          = options
    end

    def read
      read!
    end

    def read!
      target.public_send(target_attribute)
    end

    def write(value)
      write!(value)
    end

    def write!(value)
      target.public_send("#{target_attribute}=", value)
    end

    def read_as_params
      {name => read}
    end

    def write_from_params(params)
      write(params[name]) if params.key?(name)
    end
  end
end
