module Flatter
  module Mapper::Validation
    extend ActiveSupport::Concern

    included do
      validate :target_validation
    end

    def target_validation
      return if target_valid?

      errors.add(:target, :invalid)

      local_mappings.each do |mapping|
        target.errors[mapping.target_attribute].each do |message|
          errors.add(mapping.name, message)
        end
      end
    end
    private :target_validation

    def target_valid?
      !target.respond_to?(:valid?) || target.valid?
    end
    private :target_valid?
  end
end
