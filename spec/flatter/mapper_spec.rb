require 'spec_helper'

module Flatter
  module MapperSpec
    class A
      include ActiveModel::Model
    end

    class AA
    end

    class MapperA < Mapper
    end
  end

  describe Mapper do
    let(:model)  { MapperSpec::A.new }
    let(:mapper) { MapperSpec::MapperA.new(model) }

    describe '#model_name' do
      it 'delegates to target class' do
        expect(MapperSpec::A).to receive(:model_name).at_least(:once).and_call_original
        expect(mapper.model_name).to be MapperSpec::A.model_name
      end

      context 'when target class is not a model' do
        let(:model) { MapperSpec::AA.new }

        it 'still has a model_name' do
          expect(mapper.model_name.element).to eq 'mapper_a'
        end
      end
    end

    describe '#inspect' do
      it 'uses #to_s' do
        expect(mapper).to receive(:to_s).and_return 'Inspection'
        expect(mapper.inspect).to eq 'Inspection'
      end
    end
  end
end
