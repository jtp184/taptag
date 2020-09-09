module Taptag
  # Attach NFC Functions from C library in ruby
  module PN532
    # The data structure defined in the spec for the NFC radio
    class PN532Struct < FFI::Struct
      layout :reset, callback([], :int),
             :read_data, callback(%i[pointer uint16], :int),
             :write_data, callback(%i[pointer uint16], :int),
             :wait_ready, callback([:uint32], :bool),
             :wakeup, callback([], :int),
             :log, callback([:char], :void)
    end

    # C Level buffer for data
    class DataBuffer < FFI::Struct
      layout :buffer, [:uint8, 255]

      def to_a
        to_ptr.read_array_of_uint8(255)
      end

      def [](val)
        to_a[val]
      end

      def reset(arry = Array.new(255, 0))
        arry ||= Array.new(255, 0)
        ry = Array.new(255, 0)
                  .map
                  .with_index { |_i, x| i = arry[x] || 0 }

        to_ptr.write_array_of_uint8(ry)

        self
      end

      alias set reset

      def nonzero_length
        to_a.reject(&:zero?).length
      end
    end
  end
end
