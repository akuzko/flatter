require 'spec_helper'

module Flatter
  module MountingSpec
    class ::A
      def b
        @b ||= B.new
      end

      def d
        @d ||= D.new
      end
    end

    class ::B
      def c
        @c ||= C.new
      end
    end

    class C
    end

    class D
      def save
        true
      end
    end

    class ::AMapper < Mapper
      mount :b
    end

    class ::BMapper < Mapper
      mount :c, mapper_class_name: 'Flatter::MountingSpec::CMapper'
    end

    class CMapper < Mapper
    end
  end

  describe 'Mapper::Mounting' do
    let(:model)  { ::A.new }
    let(:mapper) { ::AMapper.new(model) }

    specify '#mountings' do
      expect(mapper.mountings.keys).to eq %w(b c)
    end

    describe ":default_mapper_class setting" do
      let(:mapper) { ::AMapper.new(model){ mount :d } }

      specify "when not set raises exception" do
        expect{ mapper.read }.to raise_error(NameError)
      end

      context "when set" do
        around do |example|
          Flatter.default_mapper_class = Mapper
          example.run
          Flatter.default_mapper_class = nil
        end

        it "uses default mapper for mounting" do
          expect_any_instance_of(MountingSpec::D).to receive(:save)
          mapper.save
        end
      end
    end
  end
end
