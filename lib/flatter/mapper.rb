module Flatter
  class Mapper
    extend ActiveSupport::Autoload

    autoload :Factory
    autoload :Options
    autoload :Target
    autoload :Mapping
    autoload :Mounting
    autoload :Traits
    autoload :AttributeMethods
    autoload :Persistence
    autoload :ModelName

    include Options
    include Target
    include Mapping
    include Mounting
    include Traits
    include AttributeMethods
    include ActiveModel::Validations
    include Persistence
    prepend ModelName

    def self.inherited(subclass)
      subclass.mappings  = mappings.dup
      subclass.mountings = mountings.dup
    end

    def inspect
      to_s
    end

    def to_ary
      nil
    end
  end
end