module Flatter
  module Mapper::ModelName
    def model_name
      target.class.try(:model_name) || super
    end
  end
end
