module Flatter
  class Extension::Mapper < Extension::Builder
    extends 'Mapper'

    def extend!
      fail_if_options_defined!

      ::Flatter::Mapper.mapper_options.concat @new_options
      ::Flatter::Mapper.send(:include, extension) if extends?
    end
  end
end
