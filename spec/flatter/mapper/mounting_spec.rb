require 'spec_helper'

module Flatter
  module MountingSpec
    class A
      def b
        @b ||= B.new
      end
    end

    class B
      def c
        @c ||= C.new
      end
    end

    class C
    end

    class MapperA < Mapper
      mount :b, mapper_class_name: 'Flatter::MountingSpec::MapperB'
    end

    class MapperB < Mapper
      mount :c, mapper_class_name: 'Flatter::MountingSpec::MapperC'
    end

    class MapperC < Mapper
    end
  end

  describe 'Mapper::Mounting' do
    let(:model)  { MountingSpec::A.new }
    let(:mapper) { MountingSpec::MapperA.new(model) }

    specify '#mountings' do
      expect(mapper.mountings.keys).to eq %w(b c)
    end
  end
end
