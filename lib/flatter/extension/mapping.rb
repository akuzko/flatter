module Flatter
  class Extension::Mapping < Extension::Builder
    extends 'Mapping'

    def extend!
      fail_if_options_defined!

      ::Flatter::Mapper.mapping_options.concat @new_options
      ::Flatter::Mapping.send(:prepend, extension)
    end

    def fail_if_options_defined!
      already_defined = ::Flatter::Mapper.mapping_options & @new_options

      if already_defined.present?
        fail StandardError, "Cannot extend with #{@ext.name}: options #{already_defined} already defined"
      end
    end
    private :fail_if_options_defined!
  end
end
