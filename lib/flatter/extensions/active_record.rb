module Flatter::Extensions
  module ActiveRecord
    extend ::Flatter::Extension

    register_as :active_record

    hooked do
      Flatter::Mapper::Collection::Concern.module_eval do
        alias build_collection_item_without_ar build_collection_item

        def build_collection_item
          return build_collection_item_without_ar unless mounter!.try(:ar?)

          mounter!.target.association(name.to_sym).try(:build) ||
            build_collection_item_without_ar
        end
      end
    end

    factory.extend do
      def default_target_from(mapper)
        return super unless mapper.ar?

        target_from_association(mapper.target) || super
      end
      private :default_target_from

      def target_from_association(target)
        reflection = reflection_from_target(target)

        return unless reflection.present?

        case reflection.macro
        when :has_one, :belongs_to
          target.public_send(name) || target.public_send("build_#{name}")
        when :has_many
          association = target.association(reflection.name)
          collection? ? association.load_target : association.build
        end
      end
      private :target_from_association

      def reflection_from_target(target)
        target_class = target.class
        reflection   = target_class.reflect_on_association(name.to_sym)
        reflection || target_class.reflect_on_association(name.pluralize.to_sym)
      end
      private :reflection_from_target
    end

    mapper.add_options :foreign_key, :mounter_foreign_key do
      extend ActiveSupport::Concern
      attr_reader :ar_error

      def set_target!(target)
        super
        add_skip_autosave_association_extension_to(target.class) if ar?
        target
      end

      def apply(*)
        return super unless ar?

        ::ActiveRecord::Base.transaction do
          super or raise ::ActiveRecord::Rollback
        end
      end

      def save
        ::ActiveRecord::Base.transaction do
          begin
            @ar_error = nil
            super
          rescue ::ActiveRecord::StatementInvalid => e
            @ar_error = e
            raise ::ActiveRecord::Rollback
          end
        end
      end

      def delete_target_item(item)
        item.destroy! if ar?(item)
        super
      end

      def save_target
        return super unless ar?

        assign_foreign_keys_from_mountings
        result = target.without_association_callbacks{ target.save }
        assign_foreign_keys_for_mountings if result

        result != false
      end
      protected :save_target

      def target_valid?
        return super unless ar?
        target.without_association_callbacks{ super }
      end
      private :target_valid?

      def assign_foreign_keys_from_mountings
        associated_mountings(:mounter_foreign_key).each do |mounting|
          target[mounting.mounter_foreign_key] ||= mounting.target.id
        end
      end
      private :assign_foreign_keys_from_mountings

      def assign_foreign_keys_for_mountings
        associated_mountings(:foreign_key).each do |mounting|
          mounting.target[mounting.foreign_key] ||= target.id
        end
      end
      private :assign_foreign_keys_for_mountings

      def associated_mountings(key)
        root_mountings.select do |mounting|
          mounter = mounting.mounter
          mounter = mounter.mounter if mounter.trait?
          mounting.options.key?(key) && mounter == self
        end
      end
      private :associated_mountings

      def add_skip_autosave_association_extension_to(klass)
        return if klass.const_defined?('SkipAutosaveAssociationExtension')

        klass.const_set('SkipAutosaveAssociationExtension', skip_autosave_association_extension_for(klass))
        klass.send(:prepend, klass::SkipAutosaveAssociationExtension)
      end
      private :add_skip_autosave_association_extension_to

      def skip_autosave_association_extension_for(klass)
        association_autosave_methods = klass.instance_methods.grep(/autosave_associated_records_for_/)
        association_validation_methods = klass.instance_methods.grep(/validate_associated_records_for_/)

        Module.new do
          (association_autosave_methods + association_validation_methods).each do |name|
            define_method(name) do
              @skip_association_callbacks || super()
            end
          end

          def without_association_callbacks
            @skip_association_callbacks = true
            yield
          ensure
            remove_instance_variable('@skip_association_callbacks')
          end
        end
      end
      private :skip_autosave_association_extension_for

      def ar?(object = target)
        object.class < ::ActiveRecord::Base
      end
    end
  end
end
