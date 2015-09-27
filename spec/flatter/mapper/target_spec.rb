require 'spec_helper'

module Flatter
  module TargetSpec
    class A
      include ActiveModel::Model

      attr_accessor :a1

      def my_model
        @my_model ||= B.new(b1: 'b1')
      end
    end

    class B
      include ActiveModel::Model

      attr_accessor :b1
    end

    class MapperA < Mapper
      map :a1

      mount :b, target: ->(a){ a.my_model }, mapper_class_name: 'Flatter::TargetSpec::MapperB'
    end

    class MapperB < Mapper
      map :b1
    end
  end

  describe 'Mapper::Target' do
    let(:model)  { TargetSpec::A.new(a1: 'a1') }
    let(:mapper) { TargetSpec::MapperA.new(model) }

    it 'builds target according to option' do
      expect(mapper.mountings['b'].target).to be model.my_model
      expect(mapper.read).to eq('a1' => 'a1', 'b1' => 'b1')
    end
  end
end
