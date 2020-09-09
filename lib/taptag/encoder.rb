module Taptag
  # Handles translating messages to byte frames for writing to devices
  class Encoder
    class << self
      # Takes +str+ and converts the chars to ordinals
      def encode_string(str)
        str.chars.map(&:ord)
      end

      # Takes the +str+ and splits it into +blks+ frames
      def slice_string(str, blks)
        bloks = case blks
                when :mifare
                  16
                when :ntag
                  4
                when ->(b) { b.is_a?(Integer) }
                  blks
                end

        frames = str.each_slice(bloks).to_a
        frames.last << 0 until frames.last.length == bloks

        frames
      end

      # Returns just the write safe blocks for mifare
      def writable_mifare_blocks(blocks = nil)
        @writable_mifare_blocks ||= (1..63).to_a - (0..15).map { |x| (4 * x) + 3 }

        return @writable_mifare_blocks unless blocks

        blocks.map.with_index { |i, x| [@writable_mifare_blocks[x], i] }
      end
    end
  end
end
