module Flatter
  module Mapper::ModelName
    def model_name
      target.class.respond_to?(:model_name) ?
        target.class.model_name : super
    end
  end
end
