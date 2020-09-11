module Taptag
  # Handles translating messages to byte frames for writing to devices
  class Encoder
    class << self
      # Master input function, takes in +input+ and optional values for +fmt+ and +blk_filter+
      # and can turn strings into 2d write arrays, 2d arrays into strings,
      # and 1D arrays into 2d arrays
      def call(input, fmt = :mifare, blk_filter = writable_mifare_blocks)
        if input.is_a?(String)
          zip_blocks(slice_string(encode_string(input), fmt))
        elsif identify_2d_array(input)
          decode_string reduce_blocks(input, blk_filter)
        elsif input.is_a?(Array)
          slice_string(input, fmt)
        end
      end

      alias [] call

      # Takes +str+ and converts the chars to ordinals
      def encode_string(str)
        str.chars.map(&:ord)
      end

      # Takes +bytes+ and converts it back into a string
      def decode_string(bytes)
        bytes.map(&:chr)
             .join
             .gsub(/#{0.chr}*$/, '')
      end

      # Takes the +str+ and splits it into +blks+ frames with some shorthand
      def slice_string(str, blks)
        bloks = blk_length(blks)

        frames = str.each_slice(bloks).to_a
        frames.last << 0 until frames.last.length == bloks

        frames
      end

      # Takes in +blks+ and a +filter+ array to select blocks
      def reduce_blocks(blks, filter = writable_mifare_blocks)
        if identify_2d_array(blks)
          hsh = blks.to_h
          filter.map { |x| hsh[x] }.compact.flatten
        else
          filter.map { |x| blks[x] }.compact.flatten
        end
      end

      # Takes in the +blks+ and uses the +filter to label the frames
      def zip_blocks(blks, filter = writable_mifare_blocks)
        filter.map
              .with_index { |i, x| [i, blks[x]] }
              .reject { |_a, b| b.nil? }
      end

      # Takes in the +filter+ and zips it with blank blocks
      def blank_blocks(filter = writable_mifare_blocks, blks = Array.new(16, 0))
        filter.map do |x|
          [x, blks]
        end
      end

      # Returns just the write safe blocks for mifare
      def writable_mifare_blocks
        @writable_mifare_blocks ||= (1..63).to_a - (0..15).map { |x| (4 * x) + 3 }
      end

      private

      # Takes in an +arg+, allowing for symbols to stand in
      def blk_length(arg)
        case arg
        when :mifare
          16
        when :ntag
          4
        when ->(b) { b.is_a?(Integer) }
          arg
        end
      end

      # Takes in an +arry+ and determines whether it is a [1, n] length array
      def identify_2d_array(arry)
        arry.all? { |x| x.is_a?(Array) } &&
          arry.all? { |x| x.length == 2 } &&
          arry.all? { |x| x[0].is_a?(Integer) }
      end
    end
  end
end
