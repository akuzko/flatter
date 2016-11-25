module Flatter::Extensions
  module Skipping
    extend ::Flatter::Extension

    register_as :skipping

    hooked do
      ::Flatter::Mapper::Collection.module_eval do
        alias extract_data_without_reject extract_data

        def extract_data(params)
          extract_data_without_reject(params).tap do |data|
            data.reject!{ |params| reject_if[params] } if reject_if?
          end
        end
      end
    end

    mapper.add_options :skip_if, :reject_if do
      extend ActiveSupport::Concern

      included do
        set_callback :validate, :before, :ignore_skipped_mountings
      end

      def run_validations!
        if skipped?
          errors.clear
          true
        else
          super
        end
      end

      def run_save!
        skipped? ? true : super
      end

      def skip!
        collection.each(&:skip!) if collection?
        @skipped = true
      end

      def skipped?
        !!@skipped
      end

      def ignore_skipped_mountings
        local_mountings.each do |mapper|
          mapper.skip! if mapper.skip_if? && instance_exec(&mapper.skip_if)
        end
      end
      private :ignore_skipped_mountings
    end
  end
end
