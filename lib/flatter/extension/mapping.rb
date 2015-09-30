module Flatter
  class Extension::Mapping < Extension::Builder
    extends 'Mapping'

    def extend!
      fail_if_options_defined!

      ::Flatter::Mapper.mapping_options.concat @new_options
      ::Flatter::Mapping.send(:prepend, extension) if extends?
    end
  end
end
