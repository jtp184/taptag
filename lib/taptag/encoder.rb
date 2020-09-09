module Taptag
  # Handles translating messages to byte frames for writing to devices
  class Encoder
    class << self
      # Takes +str+ and converts the chars to ordinals
      def encode_string(str)
        str.chars.map(&:ord)
      end

      # Returns just the write safe blocks for mifare
      def writable_mifare_blocks
        @writable_mifare_blocks ||= (1..63).to_a - (0..15).map { |x| (4 * x) + 3 }
      end
    end
  end
end
