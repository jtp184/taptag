module Taptag
  module NFC
    class << self
      def firmware_version
        buffer = PN532::DataBuffer.new
        PN532.get_firmware_version(pn_struct, buffer)
        buffer[1..3]
      end

      private

      def pn_struct
        return @pn_struct if @pn_struct

        @pn_struct = PN532::PN532Struct.new
        PN532.spi_init(@pn_struct)
        PN532.sam_configuration(@pn_struct)

        @pn_struct
      end
    end
  end
end
