module Flatter::Extensions
  module Order
    extend ::Flatter::Extension

    register_as :order

    mapping.add_option :index do
      def index
        options[:index] || 0
      end
    end

    mapper.add_option :index do
      def index
        options[:index] || 0
      end

      def local_mappings
        @_local_mappings ||= super.sort_by(&:index)
      end
      protected :local_mappings

      def mappers_chain(context)
        super.sort_by do |mapper|
          index = mapper.index
          index.is_a?(Hash) ? (index[context] || 0) : index
        end
      end
      private :mappers_chain
    end
  end
end
