require 'spec_helper'

module Flatter
  module TraitsSpec
    class A
      include ActiveModel::Model

      attr_accessor :a1, :a2, :a3

      def b
        @b ||= B.new(b1: 'b1', b2: 'b2', b3: 'b3')
      end
    end

    class B
      include ActiveModel::Model

      attr_accessor :b1, :b2, :b3
    end

    class AMapper < Mapper
      map :a1

      trait :trait_a1 do
        map :a2

        mount :b, traits: :trait_b do
          map :b3
        end
      end

      trait :trait_a2 do
        map :a3
      end

      def method_a1
        a1
      end

      trait :trait_a3 do
        map :a2

        def method_a2
          a2
        end
      end

      trait :trait_a4 do
        def method_a3
          a3
        end
      end
    end

    class BMapper < Mapper
      map :b1

      trait :trait_b do
        map :b2
      end

      trait :trait_b2, extends: :trait_b

      trait :trait_b3, extends: :trait_b2
    end
  end

  describe Mapper::Traits do
    let(:model)  { TraitsSpec::A.new(a1: 'a1', a2: 'a2', a3: 'a3') }
    let(:mapper) { TraitsSpec::AMapper.new(model, :trait_a1) }

    specify 'reading information mounted via traits' do
      expect(mapper.read).to eq({a1: 'a1', a2: 'a2', b1: 'b1', b2: 'b2', b3: 'b3'}.stringify_keys)
    end

    specify 'mountings with traits' do
      expect(mapper.mountings.keys).to eq %w(trait_a1_trait b b_extension_trait trait_b_trait)
    end

    it 'writing information mounted via traits' do
      mapper.write(a1: 'a12', a2: 'a22', a3: 'a32', b1: 'b12', b2: 'b22', b3: 'b32')
      expect(model.a1).to eq 'a12'
      expect(model.a2).to eq 'a22'
      expect(model.a3).to eq 'a3'
      expect(model.b.b1).to eq 'b12'
      expect(model.b.b2).to eq 'b22'
      expect(model.b.b3).to eq 'b32'
    end

    describe 'methods sharing' do
      subject(:mapper){ TraitsSpec::AMapper.new(model, :trait_a2, :trait_a3, :trait_a4) }

      it { is_expected.to respond_to :method_a2 }
      it { is_expected.to respond_to :method_a2 }

      specify{ expect(mapper.method_a2).to eq 'a2' }
      specify{ expect(mapper.method_a3).to eq 'a3' }

      specify{ expect(mapper.mountings['trait_a3_trait'].method_a1).to eq 'a1' }
      specify{ expect(mapper.mountings['trait_a3_trait'].method_a3).to eq 'a3' }
    end

    describe '#set_target' do
      let(:other_model) { TraitsSpec::A.new }
      let(:mapper)      { TraitsSpec::AMapper.new(model, :trait_a2, :trait_a3) }

      after do
        expect(mapper.target).to be other_model
        expect(mapper.mounting(:trait_a2_trait).target).to be other_model
        expect(mapper.mounting(:trait_a3_trait).target).to be other_model
      end

      context 'when called by the root mapper' do
        it 'propagates target change to traits' do
          mapper.set_target(other_model)
        end
      end

      context 'when called by the trait mapper' do
        it 'propagates target change to root and other traits' do
          mapper.mounting(:trait_a2_trait).set_target(other_model)
        end
      end
    end

    describe "traits dependency (:extends option)" do
      let(:model)  { TraitsSpec::B.new(b1: 'b1') }
      let(:mapper) { TraitsSpec::BMapper.new(model, :trait_b3) }

      it "includes all depent traits" do
        expect(mapper.traits).to eq %i[trait_b trait_b2 trait_b3]
      end
    end
  end
end
