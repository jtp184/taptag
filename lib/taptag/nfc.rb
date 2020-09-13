require 'taptag/pn532/structs'
require 'taptag/pn532/library_constants'
require 'taptag/pn532/pn532'

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

      # Detect card format through uid length
      def card_format(cuid = card_uid)
        case cuid.length
        when PN532::MIFARE_UID_SINGLE_LENGTH
          :mifare
        when PN532::MIFARE_UID_DOUBLE_LENGTH
          :ntag
        end
      end

      ### Mifare methods ###

      # Authenticates rw access to a block
      def auth_mifare_block(blk, cuid = card_uid, key = PN532::MIFARE_DEFAULT_KEY)
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

      # Reads the data in block +blk+, preauth is automatically done with +_auth+
      def read_mifare_block(blk, _auth = auth_mifare_block(blk))
        buffer = PN532::DataBuffer.new

        resp = PN532.mifare_read_block(
          pn_struct,
          buffer,
          blk
        )

        check_error(resp)
        buffer[0...PN532::MIFARE_BLOCK_LENGTH]
      end

      # Writes the +data+ provided to the +blk+ authorizing by default with +_auth+
      def write_mifare_block(blk, data, _auth = auth_mifare_block(blk))
        buffer = PN532::DataBuffer.new.set(data)

        resp = PN532.mifare_write_block(
          pn_struct,
          buffer,
          blk
        )

        check_error(resp)
        [blk, data]
      end

      # Reads +cuid+ once, and reads blocks in +rng+ off of the card into a 2D Array
      def read_mifare_card(rng = 0...PN532::MIFARE_BLOCK_COUNT, cuid = card_uid)
        rng.map do |x|
          begin
            [x, read_mifare_block(x, auth_mifare_block(x, cuid))]
          rescue IOError
            [x, nil]
          end
        end
      end

      # Takes in a 2D array of +blocks+, of format [blk_num, data[]], a default +cuid+,
      # and the default +key+ to write multiple blocks on the card
      def write_mifare_card(blocks, cuid = card_uid, key = PN532::MIFARE_DEFAULT_KEY)
        blocks.each { |blk, data| write_mifare_block(blk, data, auth_mifare_block(blk, cuid, key)) }
      end

      ### NTag methods ###

      # Reads the +blk+ off of the card, guards to prevent an uninitialized card
      def read_ntag_block(blk)
        buffer = PN532::DataBuffer.new

        resp = PN532.ntag_read_block(
          pn_struct,
          buffer,
          blk
        )

        check_error(resp)

        buffer[0...PN532::NTAG2XX_BLOCK_LENGTH]
      rescue IOError => e
        raise e unless e.message =~ /ERROR_CONTEXT/

        card_uid
        sleep 1
        read_ntag_block(blk)
      end

      # Writes the +data+ to the +blk+
      def write_ntag_block(blk, data)
        buffer = PN532::DataBuffer.new.set(data)

        resp = PN532.ntag_write_block(
          pn_struct,
          buffer,
          blk
        )

        check_error(resp)

        [blk, data]
      end

      # Reads the blocks in +rng off of the card into a 2D Array
      def read_ntag_card(rng = 0...PN532::NTAG2XX_BLOCK_COUNT)
        rng.map do |x|
          begin
            [x, read_ntag_block(x)]
          rescue IOError
            [x, nil]
          end
        end
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
                     .select { |x, _y| x.to_s.downcase =~ /error/ }
                     .key(resp)

          raise IOError, "PN532 Error (#{err || resp})" unless block_given?

          yield err, resp
        else
          resp
        end
      end
    end
  end
end
