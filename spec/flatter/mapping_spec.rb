require 'spec_helper'

module Flatter
  module MappingSpec
    class A
      include ActiveModel::Model

      attr_accessor :a1
    end

    class MapperA < Mapper
      def upcase(val)
        val.upcase
      end

      def assign(value)
        target.a1 = value.split('')
      end

      def assign2(value, name)
        target.a1 = name + value
      end
    end
  end

  RSpec.describe Mapping do
    let(:model)   { MappingSpec::A.new(a1: 'a1') }
    let(:mapper)  { MappingSpec::MapperA.new(model) }
    let(:options) { {} }
    let(:mapping) { Mapping.new(mapper, :attr1, :a1, **options) }

    specify '#read' do
      expect(mapping.read).to eq 'a1'
    end

    specify '#read_as_params' do
      expect(mapping.read_as_params).to eq('attr1' => 'a1')
    end

    specify '#write' do
      expect{ mapping.write('a2') }.
        to change{ model.a1 }.from('a1').to('a2')
    end

    specify '#write_from_params' do
      expect{ mapping.write_from_params('attr1' => 'attr1', 'a1' => 'a11') }.
        to change{ model.a1 }.from('a1').to('attr1')
    end

    describe 'Scribe extension' do
      context 'with :reader option' do
        let(:options) { {reader: reader} }
        subject { mapping.read }

        context 'as Proc' do
          let(:reader) { ->(value){ upcase(value * 2) } }

          it { is_expected.to eq 'A1A1' }
        end

        context 'as String' do
          let(:reader) { 'upcase' }

          it { is_expected.to eq 'A1' }
        end

        context 'as Symbol' do
          let(:reader) { :upcase }

          it { is_expected.to eq 'A1' }
        end

        context 'as false' do
          let(:reader) { false }

          it { is_expected.to be nil }

          specify '#read_as_params' do
            expect(mapping.read_as_params).to eq({})
          end
        end

        context 'as arbitrary value' do
          let(:object) { Object.new }
          let(:reader) { object }

          it { is_expected.to be object }
        end
      end

      context 'with :writer option' do
        let(:options) { {writer: writer} }

        subject { model.a1 }

        context 'and meaningfull value' do
          before  { mapping.write('value') }

          context 'as Proc' do
            let(:writer) { ->(value, name) { assign(value + name) } }

            it { is_expected.to eq %w(v a l u e a t t r 1) }
          end

          context 'as String' do
            let(:writer) { 'assign' }

            it { is_expected.to eq %w(v a l u e) }
          end

          context 'as Symbol' do
            let(:writer) { :assign2 }

            it { is_expected.to eq 'attr1value' }
          end

          context 'as false' do
            let(:writer) { false }

            it { is_expected.to eq 'a1' }
          end
        end

        context 'and erroneous value' do
          let(:writer) { Object.new }

          specify do
            expect{ mapping.write('foo') }.to raise_error(Mapping::Scribe::BadWriterError)
          end
        end
      end
    end
  end
end
