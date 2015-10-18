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
      mappers_chain(:validate).each(&:run_validations!)
      consolidate_errors!
      errors.empty?
    end

    def run_validations!
      errors.clear
      with_callbacks(:validate)
    end

    def save
      results = mappers_chain(:save).map(&:run_save!)
      results.all?
    end

    def run_save!
      with_callbacks(:save){ save_target }
    end

    def mappers_chain(context)
      root_mountings.dup.unshift(self)
    end
    private :mappers_chain

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
      root_mountings.each do |mounting|
        prefix = mounting.prefix
        mounting.errors.to_hash.each do |name, errs|
          error_key = [prefix, name].compact.join('.')
          errors.messages.merge!(error_key.to_sym => errs){ |key, old, new| old + new }
        end
      end
    end
    private :consolidate_errors!

    def prefix
      nil
    end
    protected :prefix

    def errors
      trait? ? mounter.errors : super
    end
  end
end
