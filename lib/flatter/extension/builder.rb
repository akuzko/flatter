module Flatter
  class Extension::Builder
    def self.extends(target_name)
      @target_name = target_name
    end

    def self.target_name
      @target_name
    end

    def initialize(ext)
      @ext = ext
      @new_options = []
    end

    def add_option(*options)
      @new_options.concat options
      extend(&Proc.new) if block_given?
    end
    alias_method :add_options, :add_option

    def extend(&block)
      @extension_block = block
    end

    def extension
      extension = Module.new
      extension.module_eval(&@extension_block) if @extension_block.present?
      extension.module_eval(new_option_helpers) if @new_options.present?
      @ext.const_set(self.class.target_name, extension)
      extension
    end
    private :extension

    def new_option_helpers
      code = @new_options.map do |option|
        <<-RUBY
          def #{option}
            options[:#{option}]
          end

          def #{option}?
            options.key?(:#{option})
          end
        RUBY
      end

      code.join("\n")
    end
    private :new_option_helpers
  end
end
