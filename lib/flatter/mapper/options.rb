module Flatter
  module Mapper::Options
    attr_reader :options

    def initialize(*, **options)
      @options  = options
    end
  end
end
