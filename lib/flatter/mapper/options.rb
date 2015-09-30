module Flatter
  module Mapper::Options
    extend ActiveSupport::Concern

    module FactoryMethods
      def create(*)
        super.tap do |mapper|
          mapper.options.merge! options.slice(*Mapper.mapper_options)
        end
      end
    end

    module ClassMethods
      def mapper_options
        @@mapper_options ||= []
      end
    end

    attr_reader :options

    def initialize(*, **options)
      @options  = options
    end
  end
end
