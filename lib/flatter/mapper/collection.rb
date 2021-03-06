module Flatter
  module Mapper::Collection
    NonUniqKeysError = Class.new(RuntimeError)

    def self.prepended(base)
      base.send(:include, Concern)
    end

    module FactoryMethods
      def create(*)
        super.tap do |mapper|
          mapper.options.merge!(collection: collection?)
        end
      end

      def default_mapper_class_name
        collection? ? "#{name.singularize.camelize}Mapper" : super
      end

      def collection?
        options[:collection] == true ||
          (options[:collection] != false && name == name.pluralize)
      end
    end

    module Concern
      extend ActiveSupport::Concern

      included do
        mapper_options.push(:collection, :item_index)
        attr_accessor :item_index
      end

      module ClassMethods
        def key(arg = nil)
          args    = []
          options = {writer: false}

          case arg
          when String, Symbol
            options[:key] = arg.to_sym
          when Proc
            args << :key
            options[:reader] = arg
          else
            fail ArgumentError, "Cannot use '#{arg}' as collection key"
          end

          map *args, **options
        end
      end

      def remove_items(keys)
        collection.reject! do |item|
          (item[:key].nil? || keys.include?(item[:key])) &&
            delete_target_item(item.target)
        end
      end
      private :remove_items

      def delete_target_item(item)
        !!target.delete(item)
      end

      def update_item(key, params)
        collection.find{ |item| item[:key] == key }.write(params)
      end

      def add_item(params)
        collection << clone.tap do |mapper|
          item = build_collection_item
          mapper.reset_locals!
          mapper.set_target!(item)
          mapper.item_index = collection.length
          mapper.write(params)
          add_item_to_target(item)
        end
      end

      def build_collection_item
        target_class.new
      end
      private :build_collection_item

      def add_item_to_target(item)
        target << item unless target.include?(item)
      end
      private :add_item_to_target
    end

    def read
      return super unless collection?

      values = collection.map(&:read)

      assert_key_uniqueness!(values)

      {name => values}
    end

    def write(params)
      return super unless collection?
      return unless params.key?(name)

      data = extract_data(params)

      assert_collection!(data)

      keys = collection.map(&:key)
      remove_items(keys - data.map{ |p| p[:key] })

      data.each do |params|
        if params.key?(:key)
          update_item(params[:key], params.except(:key))
        else
          add_item(params)
        end
      end
    end

    def extract_data(params)
      params[name]
    end
    private :extract_data

    def pluralize!
      @_pluralized = true
    end

    def pluralized?
      !!@_pluralized
    end

    def mapping_names
      super.map{ |name| collection? || pluralized? ? name.pluralize : name }
    end

    def mounting_names
      super.map{ |name| pluralized? ? name.pluralize : name }
    end

    def local_mountings
      super.each{ |mapper| mapper.pluralize! if collection? || pluralized? }
    end
    protected :local_mountings

    def assert_key_uniqueness!(values)
      keys = values.map{ |v| v['key'] }.compact
      keys == keys.uniq or
        fail NonUniqKeysError, "All keys in collection '#{name}' should be uniq, but were not"
    end
    private :assert_key_uniqueness!

    def assert_collection!(data)
      unless data.respond_to?(:each)
        fail ArgumentError, "Cannot write to '#{name}': argument is not a collection"
      end
    end
    private :assert_collection!

    def collection
      return nil unless collection?

      @collection ||= target.each.with_index.map do |item, index|
        clone.tap do |mapper|
          mapper.reset_locals!
          mapper.set_target! item
          mapper.item_index = index
        end
      end
    end

    def prefix
      return super if mounter.nil?

      [mounter.prefix, item_name].compact.join(?.).presence
    end
    protected :prefix

    def item_name
      "#{name}.#{item_index}" if item_index.present?
    end
    protected :item_name

    def as_inner_mountings
      if collection?
        ensure_target!
        collection.map{ |item| item.as_inner_mountings }
      else
        super
      end
    end
    protected :as_inner_mountings

    def reset_locals!
      @_local_mappings = nil
      @_local_mountings = nil
    end
    protected :reset_locals!

    def collection?
      options[:collection] && item_index.nil?
    end
  end
end
