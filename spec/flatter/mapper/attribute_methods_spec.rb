require 'spec_helper'

module Flatter
  module AttributeMethodsSpec
    class A
      include ActiveModel::Model

      attr_accessor :a1, :a2
    end

    class MapperA < Mapper
      map :a1, attr2: :a2
    end
  end

  describe 'Mapper::AttributeMethods' do
    let(:model)  { AttributeMethodsSpec::A.new(a1: 'a1', a2: 'a2') }
    let(:mapper) { AttributeMethodsSpec::MapperA.new(model) }

    it 'reads and writes via attribute methods' do
      expect(mapper.a1).to eq 'a1'
      mapper.attr2 = 'a22'
      expect(model.a2).to eq 'a22'
    end
  end
end
