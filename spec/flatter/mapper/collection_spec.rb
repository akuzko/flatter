require 'spec_helper'

module Flatter
  module CollectionSpec
    class A
      include ActiveModel::Model

      attr_accessor :a

      def bs
        @bs ||= Array.new(3){ |i| B.new(id: i + 1, b: i + 1) }
      end

      def ds
        @ds ||= Array.new(3){ |i| D.new(id: i + 1, d: i + 1) }
      end
    end

    class B
      include ActiveModel::Model

      attr_accessor :b, :id

      def c
        @c ||= C.new(c: b.to_s + 'c')
      end
    end

    class C
      include ActiveModel::Model

      attr_accessor :c
    end

    class D
      include ActiveModel::Model

      attr_accessor :d, :id

      def e
        @e ||= E.new(e: d.to_s + 'e')
      end
    end

    class E
      include ActiveModel::Model

      attr_accessor :e
    end

    class AMapper < Flatter::Mapper
      map :a

      mount :bs do
        mount :c
      end

      mount :ds do
        key -> { target.id }
      end
    end

    class BMapper < Flatter::Mapper
      key :id
      map :b
    end

    class CMapper < Flatter::Mapper
      map :c
    end

    class DMapper < Flatter::Mapper
      map :d

      mount :e
    end

    class EMapper < Flatter::Mapper
      map :e

      validate :odd_validation

      def odd_validation
        errors.add :e, 'cannot be odd' if e.to_i.odd?
      end
    end
  end

  describe Mapper::Collection do
    let(:a)      { CollectionSpec::A.new a: "a" }
    let(:mapper) { CollectionSpec::AMapper.new(a) }

    describe "reading data" do
      subject{ mapper.read }

      its(["a"])  { is_expected.to eq "a" }
      its(["bs"]) { is_expected.to eq [
        {"key" => 1, "b" => 1, "c" => "1c"},
        {"key" => 2, "b" => 2, "c" => "2c"},
        {"key" => 3, "b" => 3, "c" => "3c"}] }
      its(["ds"]) { is_expected.to eq [
        {"key" => 1, "d" => 1, "e" => "1e"},
        {"key" => 2, "d" => 2, "e" => "2e"},
        {"key" => 3, "d" => 3, "e" => "3e"}] }
    end

    describe "writing" do
      context "when key is present in collection" do
        let(:params) {{
          bs: [
            {key: 1, b: 11},
            {key: 2, c: '22c'},
            {key: 3}
          ]
        }}

        it "updates targets according to params" do
          mapper.write(params)

          expect(a.bs[0].b).to eq 11
          expect(a.bs[0].c.c).to eq "1c"
          expect(a.bs[1].b).to eq 2
          expect(a.bs[1].c.c).to eq "22c"
          expect(a.bs[2].b).to eq 3
          expect(a.bs[2].c.c).to eq "3c"
        end
      end

      context "when keys are missing in collection" do
        let(:params){ {bs: [key: 1]} }

        it "removes unnecessary items" do
          expect_any_instance_of(CollectionSpec::BMapper).
            to receive(:remove_items).with([2, 3]).and_call_original

          expect{ mapper.write(params) }.to change{ a.bs.length }.from(3).to(1)
          expect(mapper.read["bs"]).to eq ["key" => 1, "b" => 1, "c" => "1c"]
        end
      end

      context "when new items appear" do
        let(:params){ {bs: [{b: 4, c: 4}, {b: 5}, {c: 6}]} }

        it "adds new objects and mappers to collections" do
          expect_any_instance_of(CollectionSpec::BMapper).
            to receive(:remove_items).with([1, 2, 3]).and_call_original

          mapper.write(params)

          expect(a.bs[0].b).to eq 4
          expect(a.bs[0].c.c).to eq 4
          expect(a.bs[1].b).to eq 5
          expect(a.bs[1].c.c).to eq '5c'
          expect(a.bs[2].b).to be nil
          expect(a.bs[2].c.c).to eq 6

          mapper.read["bs"].each do |attrs|
            expect(attrs["key"]).to be nil
          end
        end
      end

      context "when data is not a collection" do
        let(:params){ {ds: "foo"} }

        it "raises error" do
          expect{ mapper.write(params) }.
            to raise_error(ArgumentError, "Cannot write to 'ds': argument is not a collection")
        end
      end
    end

    specify "attribute methods" do
      expect(mapper.bs).to eq mapper.read["bs"]
    end

    specify "errors consolidation" do
      expect(mapper).not_to be_valid
      expect(mapper.errors.to_hash).to eq(
        :"ds.0.e" => ["cannot be odd"],
        :"ds.2.e" => ["cannot be odd"]
      )
    end

    describe ".key" do
      let(:mapper_class) { Class.new(Mapper) }

      subject(:define_key) { mapper_class.key key_param }

      context "when Symbol is useed" do
        let(:key_param) { :id }

        specify do
          expect(mapper_class).to receive(:map).with(key: :id, writer: false)
          define_key
        end
      end

      context "when Symbol is useed" do
        let(:key_param) { "id" }

        specify do
          expect(mapper_class).to receive(:map).with(key: :id, writer: false)
          define_key
        end
      end

      context "when Proc is useed" do
        let(:key_param) { proc{ target.object_id } }

        specify do
          expect(mapper_class).to receive(:map).with(:key, reader: key_param, writer: false)
          define_key
        end
      end

      context "when arbitrary object is used" do
        let(:key_param) { 3 }

        it "raises error" do
          expect{ define_key }.to raise_error(ArgumentError, "Cannot use '3' as collection key")
        end
      end
    end
  end
end
