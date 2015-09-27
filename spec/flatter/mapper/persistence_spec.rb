require 'spec_helper'

module Flatter
  module PersistenceSpec
    mattr_accessor :execution

    module Callbacks
      def set_callbacks_for(name, *types)
        types.each do |type|
          set_callback type, :before do
            PersistenceSpec.execution << "#{name}.before_#{type}"
          end

          set_callback type, :after do
            PersistenceSpec.execution << "#{name}.after_#{type}"
          end
        end
      end
    end

    ::Object.extend(Callbacks)

    class A
      include ActiveModel::Model

      attr_accessor :a1, :a2, :a3

      def save
        PersistenceSpec.execution << 'A.save'
      end

      def b
        @b ||= B.new
      end

      def c
        @c ||= C.new
      end

      def d
        @d ||= D.new
      end
    end

    class B
      include ActiveModel::Model

      attr_accessor :b1, :b2, :b3

      def save
        PersistenceSpec.execution << 'B.save'
      end
    end

    class C
      include ActiveModel::Model

      attr_accessor :c1, :c2

      def save
        PersistenceSpec.execution << 'C.save'
      end
    end

    class D
      include ActiveModel::Model

      attr_accessor :d1

      def save
        PersistenceSpec.execution << 'D.save'
      end
    end

    class MapperA < Mapper
      map :a1

      validates_presence_of :a1

      mount :c, mapper_class_name: 'Flatter::PersistenceSpec::MapperC', traits: :trait_c

      trait :trait_a do
        map :a2

        validates_presence_of :a2

        mount :b, mapper_class_name: 'Flatter::PersistenceSpec::MapperB', traits: [:trait_b1, :trait_b2] do
          map :b2

          set_callbacks_for 'B(e)', :validate, :save
        end

        set_callbacks_for 'trait_a', :validate, :save
      end

      mount :d, mapper_class_name: 'Flatter::PersistenceSpec::MapperD'

      set_callbacks_for 'A', :validate, :save
    end

    class MapperB < Mapper
      map :b1

      validates_presence_of :b1

      trait :trait_b1 do
        map :b2

        set_callbacks_for 'trait_b1', :validate, :save
      end

      trait :trait_b2 do
        map :b3

        set_callbacks_for 'trait_b2', :validate, :save
      end

      trait :trait_b3 do
        set_callbacks_for 'trait_b3', :validate, :save
      end

      set_callbacks_for 'B', :validate, :save
    end

    class MapperC < Mapper
      map :c1

      trait :trait_c do
        set_callbacks_for 'trait_c', :validate, :save

        validates_presence_of :c1

        def c1
          mounter.c1
        end
      end

      validates_inclusion_of :c1, in: ['c1, c2']

      set_callbacks_for 'C', :validate, :save
    end

    class MapperD < Mapper
      map :d1

      set_callbacks_for 'D', :validate, :save
    end
  end

  describe 'Mapper::Persistence' do
    let(:model)  { PersistenceSpec::A.new }
    let(:mapper) { PersistenceSpec::MapperA.new(model, :trait_a) }

    before { PersistenceSpec.execution = [] }

    describe 'validation' do
      before{ expect(mapper).not_to be_valid }

      specify 'errors consolidation' do
        expect(mapper.errors.keys).to match_array %i[a1 a2 b1 c1]
        expect(mapper.errors[:c1].length).to eq 2
      end

      specify 'callbacks execution order' do
        expect(PersistenceSpec.execution).to eq %w(
          D.before_validate
          D.after_validate
          trait_b1.before_validate
          trait_b2.before_validate
          B(e).before_validate
          B.before_validate
          B.after_validate
          B(e).after_validate
          trait_b2.after_validate
          trait_b1.after_validate
          trait_c.before_validate
          C.before_validate
          C.after_validate
          trait_c.after_validate
          trait_a.before_validate
          A.before_validate
          A.after_validate
          trait_a.after_validate
        )
      end
    end

    describe 'saving' do
      it 'saves target exaclty one time' do
        expect_any_instance_of(PersistenceSpec::A).to receive(:save).once.and_call_original
        expect_any_instance_of(PersistenceSpec::B).to receive(:save).once.and_call_original
        expect_any_instance_of(PersistenceSpec::C).to receive(:save).once.and_call_original
        expect_any_instance_of(PersistenceSpec::D).to receive(:save).once.and_call_original

        mapper.save
      end

      specify 'callbacks & methods execution order' do
        mapper.save

        expect(PersistenceSpec.execution).to eq %w(
          D.before_save
          D.save
          D.after_save
          trait_b1.before_save
          trait_b2.before_save
          B(e).before_save
          B.before_save
          B.save
          B.after_save
          B(e).after_save
          trait_b2.after_save
          trait_b1.after_save
          trait_c.before_save
          C.before_save
          C.save
          C.after_save
          trait_c.after_save
          trait_a.before_save
          A.before_save
          A.save
          A.after_save
          trait_a.after_save
        )
      end
    end

    describe '#apply' do
      it 'writes attributes' do
        expect(mapper).to receive(:write).with(a1: 'a1', b2: 'b2', c3: 'c3')
        mapper.apply(a1: 'a1', b2: 'b2', c3: 'c3')
      end

      it 'saves if valid' do
        expect(mapper).to receive(:valid?).and_return(true)
        expect(mapper).to receive(:save).and_return(true)

        expect(mapper.apply({})).to be true
      end

      it 'does not save if invalid' do
        expect(mapper).to receive(:valid?).and_return(false)
        expect(mapper).not_to receive(:save)

        expect(mapper.apply({})).to be false
      end
    end
  end
end
