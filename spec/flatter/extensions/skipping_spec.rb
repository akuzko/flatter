require 'spec_helper'

module Flatter::Extensions
  ::Flatter.use :skipping

  module SkippingSpec
    class A
      include ActiveModel::Model

      attr_accessor :a1

      def b
        @b ||= B.new
      end

      def cs
        @cs ||= Array.new(3){ C.new(c: 'c') }
      end

      def d
        @d ||= D.new
      end

      def es
        @es ||= Array.new(3){ |i| E.new(i: i, e: 'e') }
      end
    end

    class B
      include ActiveModel::Model

      def save
        true
      end
    end

    class C
      include ActiveModel::Model

      attr_accessor :c

      def save
        c << '-saved'
      end
    end

    class D
      include ActiveModel::Model

      attr_accessor :d
      attr_reader :saved

      def save
        @saved = true
      end

      def saved?
        !!@saved
      end
    end

    class E
      include ActiveModel::Model

      attr_accessor :i, :e

      def save
        e << '-saved'
      end
    end

    class AMapper < ::Flatter::Mapper
      map :a1
      mount :b
      mount :d, skip_if: -> { attr_d.blank? }
      mount :es, reject_if: -> (params) { params[:attr_e].blank? }

      set_callback :save, :before, -> { mounting(:b).skip! if a1 == 'skip!' }

      trait :with_collection do
        mount :cs

        set_callback :save, :before, -> { mounting(:cs).skip! }
      end
    end

    class BMapper < ::Flatter::Mapper
    end

    class CMapper < ::Flatter::Mapper
      map attr_c: :c
    end

    class DMapper < ::Flatter::Mapper
      map :saved, attr_d: :d
    end

    class EMapper < ::Flatter::Mapper
      key :i
      map attr_e: :e
    end
  end

  RSpec.describe Skipping do
    let(:model)  { SkippingSpec::A.new }
    let(:mapper) { SkippingSpec::AMapper.new(model) }

    specify 'when conditions are met' do
      mapper.write(a1: 'skip!')
      expect_any_instance_of(SkippingSpec::B).not_to receive(:save)
      mapper.save
      expect(mapper.mounting(:b)).to be_skipped
    end

    specify 'when conditions are not met' do
      mapper.write(a1: 'a1')
      expect_any_instance_of(SkippingSpec::B).to receive(:save)
      mapper.save
    end

    describe 'collections support' do
      let(:mapper) { SkippingSpec::AMapper.new(model, :with_collection) }

      it 'does not save items' do
        mapper.save
        expect(mapper.attr_cs).to eq %w(c c c)
      end
    end

    describe 'skip_if option' do
      context 'when conditions are met' do
        it 'skips mapper' do
          mapper.apply(attr_d: '')
          expect(mapper.mounting(:d).target).not_to be_saved
          expect(mapper.mounting(:d)).to be_skipped
        end
      end

      context 'when conditions are not met' do
        it "doesn't skip mapper" do
          mapper.apply(attr_d: 'd')
          expect(mapper.mounting(:d).target).to be_saved
          expect(mapper.mounting(:d).target.d).to eq 'd'
        end
      end

      context 'applied to collection mounting' do
        it 'skips items that have conditions met' do
          mapper.apply(es: [{attr_e: 'e1'}, {attr_e: ''}, {attr_e: 'e3'}, {attr_e: ''}])
          expect(mapper.target.es.map(&:e)).to eq ['e1-saved', 'e3-saved']
        end
      end
    end
  end
end
