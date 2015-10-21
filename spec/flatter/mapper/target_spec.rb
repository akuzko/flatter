require "spec_helper"

module Flatter
  module TargetSpec
    class A
      include ActiveModel::Model

      attr_accessor :a1

      def my_model
        @my_model ||= B.new(b1: "b1")
      end

      def model_c
        @model_c ||= C.new(c1: "c1")
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

    class AMapper < Mapper
      map :a1

      mount :b, target: ->(a){ a.my_model }

      trait :valid_c do
        mount :c, target: :model_c
      end

      trait :invalid_c do
        mount :c, target: :c_model
      end

      trait :arbitrary_c do
        mount :c, target: 5
      end

      def model_c
        target.model_c
      end
      private :model_c
    end

    class AAMapper < Mapper
      mount :bb, mapper_class_name: 'Flatter::TargetSpec::BMapper'
    end

    class BMapper < Mapper
      map :b1
    end

    class CMapper < Mapper
      map :c1
    end
  end

  describe Mapper::Target do
    let(:model)  { TargetSpec::A.new(a1: "a1") }
    let(:mapper) { TargetSpec::AMapper.new(model, :valid_c) }

    it "builds target according to option" do
      expect(mapper.mountings["b"].target).to be model.my_model
      expect(mapper.mountings["c"].target).to be model.model_c
      expect(mapper.read).to eq("a1" => "a1", "b1" => "b1", "c1" => "c1")
    end

    context "when target is an arbitrary object" do
      let(:mapper) { TargetSpec::AMapper.new(model, :arbitrary_c) }

      it "uses that object" do
        expect(mapper.mounting(:c).target).to be 5
      end
    end

    context "when unable to use target" do
      let(:mapper) { TargetSpec::AMapper.new(model, :invalid_c) }

      it "fails with ArgumentError" do
        expect{ mapper.read }.to raise_error(ArgumentError)
      end
    end

    context "when cannot implicitly fetch target" do
      let(:mapper) { TargetSpec::AAMapper.new(model) }

      it "raises exception" do
        expect{ mapper.bb.target }.
          to raise_error(Mapper::Factory::NoTargetError)
      end
    end
  end
end
