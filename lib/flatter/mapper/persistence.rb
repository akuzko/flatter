module Flatter
  module Mapper::Persistence
    extend ActiveSupport::Concern

    included do
      define_callbacks :save
    end

    delegate :persisted?, to: :target

    def apply(params)
      write(params)
      valid? && save
    end

    def valid?(*)
      root_mountings.reverse.each(&:run_validations!)
      run_validations!
      consolidate_errors!
      errors.empty?
    end

    def run_validations!
      errors.clear
      with_callbacks(:validate)
    end

    def save
      results = root_mountings.reverse.map(&:run_save!)
      run_save! && results.all?
    end

    def run_save!
      with_callbacks(:save){ save_target }
    end

    def save_target
      target.respond_to?(:save) ? target.save : true
    end
    protected :save_target

    def with_callbacks(type, chain = self_mountings, &block)
      current = chain.shift
      current.run_callbacks(type) do
        chain.present? ? with_callbacks(type, chain, &block) : (yield if block_given?)
      end
    end

    def root_mountings
      inner_mountings.reject(&:trait?)
    end
    private :root_mountings

    def self_mountings
      local_mountings.select(&:trait?).unshift(self).reverse
    end
    private :self_mountings

    def consolidate_errors!
      root_mountings.map(&:errors).each do |errs|
        errors.messages.merge!(errs.to_hash){ |key, old, new| old + new }
      end
    end
    private :consolidate_errors!

    def errors
      trait? ? mounter.errors : super
    end
  end
end
