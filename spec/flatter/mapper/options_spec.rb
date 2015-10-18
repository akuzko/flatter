require 'spec_helper'

module Flatter
  module OptionsSpec
    class MapperA < Mapper
    end
  end

  describe Mapper::Options do
    let(:model)  { Object.new }
    let(:mapper) { OptionsSpec::MapperA.new(model, foo: :bar) }

    it 'has options' do
      expect(mapper.options).to eq(foo: :bar)
    end
  end
end
