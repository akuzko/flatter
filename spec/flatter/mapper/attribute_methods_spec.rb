require 'spec_helper'

module Flatter
  module AttributeMethodsSpec
    class A
      include ActiveModel::Model

      attr_accessor :a1, :a2

      def bs
        @bs ||= Array.new(3){ |i| B.new(b: i + 1) }
      end

      def c
        @c ||= C.new(c: 'c')
      end

      def d
        @d ||= D.new(d: 'd')
      end
    end

    class B
      include ActiveModel::Model

      attr_accessor :b
    end

    class C
      include ActiveModel::Model

      attr_accessor :c
    end

    class D
      include ActiveModel::Model

      attr_accessor :d
    end

    class AMapper < Mapper
      map :a1, attr2: :a2

      mount :bs
      mount :c
      mount :d
    end

    class BMapper < Mapper
      key :b
      map :b
    end

    class CMapper < Mapper
      map :c
    end

    class DMapper < Mapper
      map attr_d: :d
    end
  end

  describe Mapper::AttributeMethods do
    let(:model)  { AttributeMethodsSpec::A.new(a1: 'a1', a2: 'a2') }
    let(:mapper) { AttributeMethodsSpec::AMapper.new(model) }

    it "reads and writes via attribute methods" do
      expect(mapper.a1).to eq "a1"
      mapper.attr2 = "a22"
      expect(model.a2).to eq "a22"
    end

    it "have more priority than mounting readers" do
      expect(mapper.c).to eq "c"
    end

    it "returns a fully read mounting when matches mounting name" do
      expect(mapper.d).to eq("attr_d" => "d")
    end

    context "collections" do
      specify "singular reader returns Array of read attributes" do
        expect(mapper.b).to eq [1, 2, 3]
      end

      specify "plural reader returns read collection items" do
        expect(mapper.bs).to eq Array.new(3){ |i| {"key" => i + 1, "b" => i + 1} }
      end

      specify "direct writing raises error" do
        expect{ mapper.b = [4, 5] }.
          to raise_error("Cannot directly write to a collection")
      end
    end
  end
end
