require 'spec_helper'

module Flatter
  module AttributeMethodsSpec
    class A
      include ActiveModel::Model

      attr_accessor :a1, :a2

      def bs
        @bs ||= []
      end

      def cs
        @cs ||= Array.new(3){ |i| C.new(c: "c#{i + 1}") }
      end

      def f
        @f ||= F.new(f: 'f')
      end
    end

    class B
      include ActiveModel::Model

      attr_accessor :b1, :b2

      def d
        @d ||= D.new(d: "d")
      end
    end

    class C
      include ActiveModel::Model

      attr_accessor :c

      def e
        @e ||= E.new(e: "e")
      end

      def g
        @g ||= G.new(g: "g")
      end
    end

    class D
      include ActiveModel::Model

      attr_accessor :d
    end

    class E
      include ActiveModel::Model

      attr_accessor :e
    end

    class F
      include ActiveModel::Model

      attr_accessor :f
    end

    class G
      include ActiveModel::Model

      attr_accessor :g
    end

    class AMapper < Mapper
      map :a1

      mount :f

      trait :a_trait1 do
        map :a2
      end

      trait :a_trait2 do
        mount :bs do
          map :b2

          mount :d
        end
      end

      trait :a_trait3 do
        mount :cs, traits: :c_trait1
      end
    end

    class BMapper < Mapper
      map :b1
    end

    class CMapper < Mapper
      map attr_c: :c

      trait :c_trait1 do
        mount :e
        mount :g
      end
    end

    class DMapper < Mapper
      map attr_d: :d
    end

    class EMapper < Mapper
      map :e
    end

    class FMapper < Mapper
      map attr_f: :f
    end

    class GMapper < Mapper
      map attr_g: :g
    end
  end

  describe Mapper::AttributeMethods do
    let(:model) { AttributeMethodsSpec::A.new(a1: 'a1', a2: 'a2') }

    context "on its own" do
      let(:mapper) { AttributeMethodsSpec::AMapper.new(model) }

      it "reads and writes to all locally defined mappings and reads mountings" do
        expect(mapper.mapping_names).to eq %w(a1 attr_f)
        expect(mapper.mounting_names).to eq %w(f)
        expect(mapper).to respond_to(:a1)
        expect(mapper).to respond_to(:a1=)
        expect(mapper).to respond_to(:f)
        expect(mapper).to respond_to(:attr_f)
        expect(mapper).to respond_to(:attr_f=)
        expect(mapper).not_to respond_to(:cs)

        expect(mapper.a1).to eq model.a1
        expect(mapper.f).to eq("attr_f" => model.f.f)
        mapper.attr_f = "updated f"
        expect(model.f.f).to eq "updated f"
      end
    end

    context "with mapping defined in a trait" do
      let(:mapper) { AttributeMethodsSpec::AMapper.new(model, :a_trait1) }

      it "provides access to mappings defined via trait" do
        expect(mapper.mapping_names).to match_array %w(a1 a2 attr_f)
        expect(mapper).to respond_to(:a2)
        expect(mapper).to respond_to(:a2=)
      end
    end

    context "with complex collection mounting in a trait" do
      let(:mapper) { AttributeMethodsSpec::AMapper.new(model, :a_trait2) }

      it "provides access to deeply nested mappings, even in collection" do
        expect(mapper.mapping_names).to match_array %w(a1 attr_f b1s b2s attr_ds)
        expect(mapper.mounting_names).to match_array %w(f bs ds)

        expect(mapper.b1s).to be_an_instance_of(Array)
        expect(mapper.b2s).to be_an_instance_of(Array)
        expect(mapper.attr_ds).to be_an_instance_of(Array)

        mapper.write(bs: [
          {b1: "1b1", b2: "1b2", attr_d: "d1"},
          {b1: "2b1", b2: "2b2", attr_d: "d2"}
        ])

        expect(mapper.bs).to eq [
          {"b1" => "1b1", "b2" => "1b2", "attr_d" => "d1"},
          {"b1" => "2b1", "b2" => "2b2", "attr_d" => "d2"}
        ]

        expect(mapper.b1s).to eq %w(1b1 2b1)
        expect(mapper.attr_ds).to eq %w(d1 d2)
        expect{ mapper.b1s = ['2b1', '1b1'] }.
          to raise_error("Cannot directly write to a collection")
      end
    end

    context "with complex collection with it's own traits" do
      let(:mapper) { AttributeMethodsSpec::AMapper.new(model, :a_trait3) }

      it "provides access to nested mappings and mountings, but mappings have more priority than mountings" do
        expect(mapper).to respond_to(:cs)
        expect(mapper).to respond_to(:es)
        expect(mapper.cs).to eq [
          {"attr_c" => "c1", "e" => "e", "attr_g" => "g"},
          {"attr_c" => "c2", "e" => "e", "attr_g" => "g"},
          {"attr_c" => "c3", "e" => "e", "attr_g" => "g"}
        ]
        expect(mapper.es).to eq %w(e e e)
        expect(mapper.gs).to eq [{"attr_g" => "g"}] * 3
      end
    end
  end
end
