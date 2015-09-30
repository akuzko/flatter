module Flatter
  module Extension
    extend ActiveSupport::Autoload

    autoload :Registrar
    autoload :Builder
    autoload :Mapping
    autoload :Mapper
    autoload :Factory

    def register_as(name)
      ::Flatter.extensions[name] = self
    end
    private :register_as

    def depends_on(*extensions)
      dependencies.concat extensions
    end
    private :depends_on

    def dependencies
      @dependencies ||= []
    end

    def hook!
      return false if hooked?

      use_dependencies

      mapping.extend!
      mapper.extend!
      factory.extend!

      hook_callback!

      @hooked = true
    end

    def hooked(&block)
      @hook_callback = block
    end
    private :hooked

    def hook_callback!
      instance_exec(&@hook_callback) if @hook_callback.present?
    end
    private :hook_callback!

    def use_dependencies
      dependencies.each{ |extension| ::Flatter.use extension }
    end
    private :use_dependencies

    def hooked?
      !!@hooked
    end

    def mapping
      @mapping ||= Mapping.new(self)
    end
    private :mapping

    def mapper
      @mapper ||= Mapper.new(self)
    end
    private :mapper

    def factory
      @factory ||= Factory.new(self)
    end
    private :factory
  end
end
