module Flatter
  module Extension
    extend ActiveSupport::Autoload

    autoload :Registrar
    autoload :Builder
    autoload :Mapping
    autoload :Mounting

    def register_as(name)
      ::Flatter.extensions[name] = self
    end

    def hook!
      return false if hooked?

      mapping.extend!
      mapper.extend!

      @hooked = true
    end

    def hooked?
      !!@hooked
    end

    def mapping
      @mapping ||= Mapping.new(self)
    end

    def mapper
      @mapper ||= Mounting.new(self)
    end
  end
end
