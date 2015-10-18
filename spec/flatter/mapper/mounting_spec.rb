require 'spec_helper'

module Flatter
  module MountingSpec
    class ::A
      def b
        @b ||= B.new
      end
    end

    class ::B
      def c
        @c ||= C.new
      end
    end

    class C
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
  end
end
