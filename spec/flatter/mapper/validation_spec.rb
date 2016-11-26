require 'spec_helper'

module Flatter
  module ValidationSpec
    class A
      include ActiveModel::Model

      attr_accessor :a

      validates :a, presence: true
    end

    class AMapper < Mapper
      map attr_a: :a
    end
  end

  describe 'Mapper::Mounting' do
    let(:model)  { ValidationSpec::A.new }
    let(:mapper) { ValidationSpec::AMapper.new(model) }

    describe 'validation' do
      it 'is not valid when target has errors' do
        expect(mapper).not_to be_valid
      end

      it 'maps errors from target' do
        mapper.validate
        expect(mapper.errors.messages).to match(
          target: ["is invalid"],
          attr_a: ["can't be blank"]
        )
      end
    end
  end
end
