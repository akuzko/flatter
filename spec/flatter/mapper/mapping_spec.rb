require 'spec_helper'

module Flatter
  module MappingSpec
    class A
      include ActiveModel::Model

      attr_accessor :a1, :a2, :a3
    end

    class MapperA < Mapper
      map :a1, attr2: :a2
    end
  end

  describe 'Mapper::Mapping' do
    let(:model)  { MappingSpec::A.new(a1: 'a1', a2: 'a2', a3: 'a3') }
    let(:mapper) { MappingSpec::MapperA.new(model) }

    describe '#mappings' do
      it 'returns hash of defined mappings' do
        expect(mapper.mappings).to be_a Hash
        expect(mapper.mappings).to include 'a1', 'attr2'
      end
    end

    describe 'reading' do
      it 'reads values from target object' do
        expect(mapper.read).to eq('a1' => 'a1', 'attr2' => 'a2')
      end
    end

    describe 'writing' do
      it 'propagates values to target' do
        mapper.write(a1: 'a12', attr2: 'a22')

        expect(model.a1).to eq 'a12'
        expect(model.a2).to eq 'a22'
      end

      it 'ignores unmapped values' do
        expect{ mapper.write(a3: 'a32') }.not_to change{ model.a3 }
      end
    end
  end
end
