module Flatter::Extensions
  module Multiparam
    extend ::Flatter::Extension

    register_as :multiparam

    mapping.add_option :multiparam do
      def write(value)
        return super unless multiparam?

        write!(multiparam.new(*value))
      end
    end

    mapper.extend do
      def write(params)
        extract_multiparams!(params)

        super(params)
      end

      def extract_multiparams!(params)
        return super if collection?

        local_mappings.each do |mapping|
          next unless mapping.multiparam?

          param_keys = params.keys.
            select{ |key| key.to_s =~ /#{mapping.name}\(\d+[if]\)/ }.
            sort_by{ |key| key.to_s[/\((\d+).*\)/, 1].to_i }

          next if param_keys.empty?

          args = param_keys.each_with_object([]) do |key, values|
            value = params.delete key
            type  = key[/\(\d+([if]*)\)/, 1]

            value = if value.present?
              type.blank? ? value : value.send("to_#{type}")
            end

            values.push value
          end

          params[mapping.name] = args
        end
      end
      private :extract_multiparams!
    end
  end
end
