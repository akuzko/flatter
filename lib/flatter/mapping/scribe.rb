module Flatter
  module Mapping::Scribe
    extend Flatter::Extension

    register_as :scribe

    BadWriterError = Class.new(ArgumentError)

    mapping.add_options :reader, :writer do
      def read
        return super unless reader?

        case reader
        when Proc, String, Symbol
          args = Array((name if arity_of(reader) == 1))
          exec_or_send(reader, args)
        when false then nil
        else reader
        end
      end

      def write(value)
        return super unless writer?

        case writer
        when Proc, String, Symbol
          args = [value].tap{ |a| a << name if arity_of(writer) == 2 }
          exec_or_send(writer, args)
        when false then nil
        else fail BadWriterError, "cannot use #{writer} for assigning values"
        end
      end

      def read_as_params
        reader == false ? {} : super
      end

      def arity_of(obj)
        (obj.is_a?(Proc) ? obj : mapper.method(obj)).arity
      end
      private :arity_of

      def exec_or_send(obj, args)
        if obj.is_a?(Proc)
          mapper.instance_exec(*args, &obj)
        else
          mapper.send(obj, *args)
        end
      end
      private :exec_or_send
    end
  end
end
