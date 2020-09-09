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

      ### Mifare methods ###

      # Authenticates rw access to a block
      def auth_mifare_block(blk, cuid = nil, key = PN532::MIFARE_DEFAULT_KEY)
        cuid ||= card_uid

        raise IOError, "Can't find card" unless cuid

        uid = PN532::DataBuffer.new.set(cuid)

        resp = PN532.mifare_authenticate_block(
          pn_struct,
          uid,
          uid.nonzero_length,
          blk,
          PN532::MIFARE_CMD_AUTH_A,
          key
        )

        check_error(resp)
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

      # Guards against error by confirming a 0 response
      def check_error(resp)
        if resp != PN532::ERROR_NONE
          err = PN532.lib_constants
                     .select { |x, y| x.to_s.downcase =~ /error/ }
                     .key(resp)
          raise IOError, "PN532 Error (#{err || resp})"
        else
          resp
        end
      end
    end
  end
end
