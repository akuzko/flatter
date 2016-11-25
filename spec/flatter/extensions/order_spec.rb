require 'spec_helper'

module Flatter::Extensions
  ::Flatter.use :order

  module OrderSpec
    module Callbacks
      def set_callbacks_for(name, *types)
        types.each do |type|
          set_callback type, :before do
            OrderSpec.execution << "#{name}.before_#{type}"
          end

          set_callback type, :after do
            OrderSpec.execution << "#{name}.after_#{type}"
          end
        end
      end
    end

    ::Object.extend(Callbacks)

    def self.execution
      @execution ||= []
    end

    class A
      def initialize(name = 'A')
        @name = name
      end

      def b
        @b ||= A.new('B')
      end

      def c
        @c ||= A.new('C')
      end

      def save
        OrderSpec.execution << "#{@name}.save"
      end
    end

    class MapperA < ::Flatter::Mapper
      mount :b, mapper_class_name: 'Flatter::Extensions::OrderSpec::MapperB', index: {save: -1, validate: 1}

      set_callbacks_for 'A', :validate, :save

      trait :trait_a do
        set_callbacks_for 'trait_a', :validate, :save

        mount :c, mapper_class_name: 'Flatter::Extensions::OrderSpec::MapperC'
      end
    end

    class MapperB < ::Flatter::Mapper
      set_callbacks_for 'B', :validate, :save
    end

    class MapperC < ::Flatter::Mapper
      set_callbacks_for 'C', :validate, :save
    end
  end

  RSpec.describe Order do
    let(:model){ OrderSpec::A.new }

    context 'validation' do
      let(:mapper){ OrderSpec::MapperA.new(model, :trait_a) }

      it 'executes validation routines according to specified indices' do
        OrderSpec.execution.clear

        mapper.valid?

        expect(OrderSpec.execution).to eq %w(
          trait_a.before_validate
          A.before_validate
          A.after_validate
          trait_a.after_validate
          C.before_validate
          C.after_validate
          B.before_validate
          B.after_validate
        )
      end
    end

    context 'save' do
      let(:mapper){ OrderSpec::MapperA.new(model, :trait_a, index: 1) }

      it 'executes save routines according to specified indices' do
        OrderSpec.execution.clear

        mapper.save

        expect(OrderSpec.execution).to eq %w(
          B.before_save
          B.save
          B.after_save
          C.before_save
          C.save
          C.after_save
          trait_a.before_save
          A.before_save
          A.save
          A.after_save
          trait_a.after_save
        )
      end
    end
  end
end
