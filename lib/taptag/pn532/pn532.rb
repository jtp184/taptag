module Taptag
  # Encapsulates the C Library functions
  module PN532
    extend FFI::Library

    ffi_lib 'c'
    ffi_lib_flags :now, :global
    ffi_lib 'wiringPi'

    ffi_lib 'pn532'
    attach_function :read_passive_target, :PN532_ReadPassiveTarget,
                    %i[pointer pointer uint8 uint32], :int, blocking: true
    attach_function :sam_configuration, :PN532_SamConfiguration,
                    [:pointer], :int, blocking: true
    attach_function :get_firmware_version, :PN532_GetFirmwareVersion,
                    %i[pointer pointer], :int, blocking: true
    attach_function :mifare_authenticate_block, :PN532_MifareClassicAuthenticateBlock,
                    %i[pointer pointer uint8 uint16 uint16 pointer], :int, blocking: true
    attach_function :mifare_read_block, :PN532_MifareClassicReadBlock,
                    %i[pointer pointer uint16], :int, blocking: true
    attach_function :mifare_write_block, :PN532_MifareClassicWriteBlock,
                    %i[pointer pointer uint16], :int, blocking: true
    attach_function :ntag_read_block, :PN532_Ntag2xxReadBlock,
                    %i[pointer pointer uint16], :int, blocking: true
    attach_function :ntag_write_block, :PN532_Ntag2xxWriteBlock,
                    %i[pointer pointer uint16], :int, blocking: true

    ffi_lib 'pn532_rpi'
    attach_function :spi_init, :PN532_SPI_Init,
                    [:pointer], :void, blocking: true
    attach_function :spi_wait_ready, :PN532_SPI_WaitReady,
                    [:uint32], :bool, blocking: true

    attach_function :i2c_init, :PN532_I2C_Init,
                    [:pointer], :void, blocking: true
    attach_function :i2c_wait_ready, :PN532_I2C_WaitReady,
                    [:uint32], :bool, blocking: true

    attach_function :uart_init, :PN532_UART_Init,
                    [:pointer], :void, blocking: true
    attach_function :uart_wait_ready, :PN532_UART_WaitReady,
                    [:uint32], :bool, blocking: true
  end
end
