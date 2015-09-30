require 'spec_helper'

module Flatter
  module TargetSpec
    class A
      include ActiveModel::Model

      attr_accessor :a1

      def my_model
        @my_model ||= B.new(b1: 'b1')
      end

      def model_c
        @model_c ||= C.new(c1: 'c1')
      end
    end

    class B
      include ActiveModel::Model

      attr_accessor :b1
    end

    class C
      include ActiveModel::Model

      attr_accessor :c1
    end

    class MapperA < Mapper
      map :a1

      mount :b, target: ->(a){ a.my_model }, mapper_class_name: 'Flatter::TargetSpec::MapperB'

      trait :valid_c do
        mount :c, target: :model_c, mapper_class_name: 'Flatter::TargetSpec::MapperC'

        def model_c
          target.model_c
        end
        private :model_c
      end

      trait :invalid_c do
        mount :c, target: :c_model, mapper_class_name: 'Flatter::TargetSpec::MapperC'
      end

      trait :arbitrary_c do
        mount :c, target: Struct.new(:c1).new, mapper_class_name: 'Flatter::TargetSpec::MapperC'
      end
    end

    class MapperB < Mapper
      map :b1
    end

    class MapperC < Mapper
      map :c1
    end
  end

  describe 'Mapper::Target' do
    let(:model)  { TargetSpec::A.new(a1: 'a1') }
    let(:mapper) { TargetSpec::MapperA.new(model, :valid_c) }

    it 'builds target according to option' do
      expect(mapper.mountings['b'].target).to be model.my_model
      expect(mapper.mountings['c'].target).to be model.model_c
      expect(mapper.read).to eq('a1' => 'a1', 'b1' => 'b1', 'c1' => 'c1')
    end

    context 'when target is an arbitrary object' do
      let(:mapper) { TargetSpec::MapperA.new(model, :arbitrary_c) }

      it 'uses that object' do
        expect(mapper.mounting(:c).target).to be_kind_of(Struct)
      end
    end

    context 'when unable to use target' do
      let(:mapper) { TargetSpec::MapperA.new(model, :invalid_c) }

      it 'fails with ArgumentError' do
        expect{ mapper.read }.to raise_error(ArgumentError)
      end
    end

    context 'when initializing without a target' do
      it 'raises exception' do
        expect{ TargetSpec::MapperA.new(nil) }.
          to raise_error(Mapper::Target::NoTargetError)
      end
    end
  end
end
