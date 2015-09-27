module Flatter
  module Extension::Registrar
    UnknownExtensionError = Class.new(ArgumentError)

    def extensions
      @extensions ||= {}
    end

    def use(extension_name, **opts)
      require opts[:require] if opts[:require].present?

      extension = extensions[extension_name]

      fail UnknownExtensionError, "Unknown extension #{extension_name}" if extension.nil?

      extension.hook!
    end
  end
end
