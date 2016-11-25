require 'spec_helper'

module Flatter::Extensions
  ::Flatter.use :multiparam

  module MultiparamSpec
    class A
      include ActiveModel::Model

      attr_accessor :a1, :a2
    end

    class MapperA < ::Flatter::Mapper
      map date1: :a1, multiparam: Date
      map :a2
    end
  end

  RSpec.describe Multiparam do
    let(:params) { {'date1(3i)' => '27', 'date1(1i)' => '2015', 'date1(2i)' => '09', 'a2' => 'a2'} }
    let(:model)  { MultiparamSpec::A.new }
    let(:mapper) { MultiparamSpec::MapperA.new(model) }
    let!(:date)  { Date.new(2015, 9, 27) }

    it 'extracts multiparams' do
      expect(Date).to receive(:new).with(2015, 9, 27).and_call_original
      mapper.write(params)
      expect(model.a1).to eq date
      expect(model.a2).to eq 'a2'
    end
  end
end
