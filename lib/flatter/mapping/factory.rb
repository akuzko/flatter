module Flatter
  class Mapping::Factory
    def initialize(*args)
      @args = args
    end

    def create(mapper)
      Mapping.new(mapper, *@args)
    end
  end
end
