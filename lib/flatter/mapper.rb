module Flatter
  class Mapper
    extend ActiveSupport::Autoload

    autoload :Factory
    autoload :Options
    autoload :Mapping
    autoload :Mounting
    autoload :Traits
    autoload :Target
    autoload :AttributeMethods
    autoload :Persistence
    autoload :ModelName
    autoload :Collection
    autoload :WriteWithIndifferentAccess

    include Options
    include Mapping
    include Mounting
    include Traits
    include Target
    include AttributeMethods
    include ActiveModel::Validations
    include Persistence
    prepend ModelName
    prepend Collection
    prepend WriteWithIndifferentAccess

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