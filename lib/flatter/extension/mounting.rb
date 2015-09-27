module Flatter
  class Extension::Mounting < Extension::Builder
    extends 'Mapper'

    def extend!
      ::Flatter::Mapper.send(:include, extension)
    end
  end
end
