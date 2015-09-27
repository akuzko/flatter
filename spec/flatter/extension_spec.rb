require 'spec_helper'

module Flatter
  module ExtensionSpec
    module Extension
      extend ::Flatter::Extension

      register_as :spec_ext

      mapping.add_option :foo do
        def read
          return 'foo!' if foo?
          super
        end
      end

      mapper.add_option :bar

      mapper.extend do
        def write(params)
          do_something_with(params)
          super
        end

        def do_something_with(*)
        end
      end
    end

    ::Flatter.configure do |f|
      f.use :spec_ext
    end

    class A
      include ActiveModel::Model

      attr_accessor :a1, :a2
    end

    class MapperA < Mapper
      map :a1, foo: true
      map :a2
    end
  end

  describe 'Flatter::Extensions' do
    let(:model)  { ExtensionSpec::A.new(a1: 'a1', a2: 'a2') }
    let(:mapper) { ExtensionSpec::MapperA.new(model, bar: :bar) }

    it 'adds mapping option to mapping options list' do
      expect(ExtensionSpec::MapperA.mapping_options).to include :foo
    end

    describe 'extended behavior' do
      specify 'for mapping' do
        expect(mapper.read).to eq('a1' => 'foo!', 'a2' => 'a2')
      end

      specify 'for mapper' do
        params = {a1: 'a11', a2: 'a22'}
        expect(mapper).to respond_to(:bar)
        expect(mapper).to be_bar
        expect(mapper.bar).to be :bar
        expect(mapper).to receive(:do_something_with).with(params)
        mapper.write(params)
      end
    end
  end
end
