module Flatter
  class Extension::Factory < Extension::Builder
    extends 'Factory'

    def extend!
      ::Flatter::Mapper::Factory.send(:prepend, extension) if extends?
    end
  end
end
