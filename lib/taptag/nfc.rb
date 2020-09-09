module Taptag
  # The higher level interface to the hardware, implements reading and writing functions using ruby
  # conventions.
  module NFC
    class << self
      # Returns the firmware version reported by the device as a byte array
      def firmware_version
        buffer = PN532::DataBuffer.new
        PN532.get_firmware_version(pn_struct, buffer)
        buffer[1..3]
      end

      # Invokes PN532#read_passive_target to get the uid length and return a byte array
      def card_uid
        buffer = PN532::DataBuffer.new

        resp = PN532.read_passive_target(
          pn_struct,
          buffer,
          PN532::MIFARE_ISO14443A,
          1000
        )

        return if resp == PN532::STATUS_ERROR

        buffer[0...resp]
      end

      private

      # Initializes and memoizes a PN532Struct for device control
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
