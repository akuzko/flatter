module Flatter
  module Mapper::WriteWithIndifferentAccess
    def write(params)
      super(params.with_indifferent_access)
      params
    end
  end
end
