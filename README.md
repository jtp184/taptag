# Taptag

![taptag_header](https://justinp-io-production.s3.amazonaws.com/store/835c2d89bbe994dc493af2d34a00b877.gif)

Taptag is a gem for interacting with Waveshare's PN532 NFC HAT. It includes methods for reading and writing from Mifare and Ntag NFC tags, as well as simple mechanisms for storing and retrieving data.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'taptag', github: 'jtp184/taptag'
```

You can also download and install it globally with

```bash
git clone https://github.com/jtp184/taptag.git
cd taptag
rake install
```

For help setting up your pi for use with this gem, check out the [RASPI_SETUP](https://github.com/jtp184/taptag/blob/master/RASPI_SETUP.md) instructions

## Hardware

This gem was developed using Waveshare's [PN532 NFC HAT](https://www.waveshare.com/wiki/PN532_NFC_HAT) on the Raspberry Pi 3+, and using Mifare and NTag tags purchased online.

### Waveshare Code

The waveshare code is made available in the `vendor` folder for compiling on your own system. These C libraries, as well as the [wiringPi](http://wiringpi.com/) library are *mandatory* runtime dependencies, and the NFC specific parts of the gem will not successfully `require` without them present in the `LD_LIBRARY_PATH`. On the pi, this can be achieved by running the [`install_deps`](https://github.com/jtp184/taptag/blob/master/bin/pi/install_deps) script and selecting the "Waveshare NFC Code" option. wiringPi is included by default on Raspbian.

Installing the libraries on the host machine is more difficult. Cross-OS C code compilation is beyond the scope of this gem, but on a linux platform (I use [arch](https://archlinux.org/)) you can follow the instructions for compiling [wiringPi](http://wiringpi.com/download-and-install/) from [source](https://github.com/WiringPi/WiringPi). You can then compile the libraries and add them to your system's C libraries with

```bash
cd ./vendor
gcc -c -Wall -Werror -fpic pn532.c
gcc -c -Wall -Werror -fpic pn532_rpi.c

gcc -shared -o libpn532.so pn532.o
gcc -shared -o libpn532_rpi.so pn532_rpi.o

sudo mv lib*.so /usr/lib
rm *.*o
```

## Usage

### Documentation

All methods and classes are RDoc documented at https://jtp184.github.io/taptag/

### NFC

The `NFC` class is the high level interface to the reader. It can be used to get uids, and read from and write to NFC tags, for both Mifare and NTag cards. It requires the C libraries and wiringPi, and is not required by default for ease of development.

```ruby
require 'taptag/nfc'

Taptag::NFC.firmware_version # => [1, 6, 7]
Taptag::NFC.card_uid # => array of uid bytes, or nil if no card is detected
```

### Communication Interface

Taptag defaults to using SPI.  To use with I2C or UART:

```
Taptag::NFC.interface_type = :i2c
```
or
```
Taptag::NFC.interface_type = :uart
```

#### Mifare Cards

Taptag gives you fine control over read functions, with sensible defaults

```ruby
require 'taptag/nfc'

# Mifare blocks need to be authorized for reading, using their uid and a key
cid = Taptag::NFC.card_uid
ky = Taptag::PN532::MIFARE_DEFAULT_KEY # Needs to be a FFI::Struct

Taptag::NFC.auth_mifare_block(6, cid, ky)

# If they aren't supplied, the card_uid is called for and the default key is used
a = Taptag::NFC.auth_mifare_block(6) # Same as above line

# You can skip doing auth by passing it as the second argument to read
Taptag::NFC.read_mifare_block(6, a)
# Or perform it implicitly by passing nothing at all
Taptag::NFC.read_mifare_block(6) # => Calls auth_mifare_block(6), and returns an array of bytes

# You can also read multiple blocks at once
Taptag::NFC.read_mifare_card(0..10) # => [0, [89, 101, 101...], 1, [114, 107...]...10, [...]]

# Passing no argument reads all of the blocks
Taptag::NFC.read_mifare_card.length # => 64

# It's also possible to pass arbitrary blocks
Taptag::NFC.read_mifare_card([6, 12, 22]).length # => 3
```

Write functions are similarly simple

```ruby
require 'taptag/nfc'

# Mifare writes need to be authorized, which is handled like reads, so you can simply do
Taptag::NFC.write_mifare_block(6, Array.new(16, &:itself))

# If you need to, the auth is providable as the last argument
Taptag::NFC.write_mifare_block(6, Array.new(16, 0), Taptag::NFC.auth_mifare_block(6))

# You can also write multiple blocks at once. Pass a 2D array with indexes
blks = [
  [1, Array.new(16, 0)],
  [2, Array.new(16, 255)]
]

Taptag::NFC.write_mifare_card(blks) # You can also pass card_uid and key
```

#### NTag Cards

NTag cards are very similar, except they don't have an auth step

```ruby
require 'taptag/nfc'

# Read a single block
Taptag::NFC.read_ntag_block(15) # => [69, 114, 101, 107]

# Or multiple blocks
Taptag::NFC.read_ntag_card([21, 23, 25]).length # => 3

# Or an entire card
Taptag::NFC.read_ntag_card # => [0, [...]...]
```

### Encoder

The `Encoder` class translates strings to byte arrays and back again, using `String#ord`. It allows you to easily prepare data to be stored in NFC tags, and decode the data you've stored there.

```ruby
require 'taptag/nfc'

str0 = "Elfangor-Sirinial-Shamtul"

# You can turn a string into ordenal codepoints
bytes0 = Taptag::Encoder.encode_string(str0) # => [69, 108, 102, 97...]

# And reverse it
str1 = Taptag::Encoder.decode_string(bytes0) # => "Elfangor-Sirinial-Shamtul"

# Slice those codepoints into frames, with padding
frames = Taptag::Encoder.slice_string(bytes0, 16) # => [[69, 108, 102...], [108, 45, 83...]]

# And zip them up with block ids
blocks = Taptag::Encoder.zip_block(frames, [1, 2]) # => [1, [69...],  2, [108...]]

# Reverse is to reduce them, if you don't provide a filter argument it defaults to mifare blocks
Taptag::Encoder.reduce_blocks(frames) # => [69, 108...]

# The array is now suitible for passing to the NFC object
Taptag::NFC.write_mifare_card(blocks)

# Using the .call function automagically applies the apropriate steps to objects

bytes1 = Taptag::Encoder.call('Yeerk') # => [[1, [89, 101, 101, 114, 107, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]]]
str2 = Taptag::Encoder.call(bytes1) # => 'Yeerk'
bytes2 = Taptag::Encoder.call(bytes0) # => [[69, 108...], [108, 45...]]

# And is aliased to .[] for ease of use

Taptag::Encoder['Tobias'] # => [1, [84, 111...]]

# The encoder also can return an array of blank blocks
Taptag::Encoder.blank_blocks # => [1, [0...], 2, [0...]]

# Or customizable repeated frames by passing arguments
Taptag::Encoder.blank_blocks([1, 2, 4], Array.new(16, 128)) # => [1, [128, 128...], 2, [128, 128...]]

```

### Encrypter

The `Encrypter` class is a frontend for the stdlib OpenSSL library, allowing you to store your data on tags securely.

```ruby
str = "Escafil Device"

# With only string argument, randomly generates and returns random key and initial vector
enc0 = Taptag::Encrypter.encrypt(str)
# => {
#      :key=>"l\xD6n2\x9D\x82\x8C\xE4\x9FPX\xF0v\xB6\x82\xD0",
#      :vector=>"~\ti)f\xCC\xF3\x7F\xE1\xF1\xF0^\xCB\x9F\x12M",
#      :data=>"\v\xDE\xAF\xA1\xF3,\x1C\xD5\xF2)\xC2\x90\xD0\f9N"
#    }

# You can also pass them in if you need to
Taptag::Encrypter.encrypt(str, key: enc0[:key], vector: enc0[:vector])

# You can also choose the algorithm used, which is AES-128-CBC by default
Taptag::Encrypter.encrypt(str, algorithm: 'AES-256-CBC')

# Decrypting requires the vector, key, and data
Taptag::Encrypter.decrypt(enc0) # => "Escafil Device"
```

For examples of storing data on device, check out [the examples](https://github.com/jtp184/taptag/blob/master/bin/example). Here's a simple, albeit insecure workflow

```ruby
require 'taptag/nfc'

str = 'Pemalite Crystal'

enc = Taptag::Encrypter.encrypt(str)

# We join the key, vector, and encrypted data into a single string and encode it.
# Since the key and vector are 16 bytes long, they become blocks 1 and 2
Taptag::NFC.write_mifare_card(Taptag::Encoder[enc.values.join])

# When we decode, we grab all the blocks
blocks = Taptag::NFC.read_mifare_card

dc = {}

# We only write to valid blocks thanks to the encoder
dc[:key] = blocks[1].last.map(&:chr).join
dc[:vector] = blocks[2].last.map(&:chr).join

# We can decode the string and then discard the key and vector bytes
dc[:data] = Taptag::Encoder[blocks][32..-1]

# And then decrypt our data
Taptag::Encrypter.decrypt(dc) # => 'Pemalite Crystal'

```

### PN532

The `PN532` module uses the FFI library to access the C library code provided by Waveshare. It's required by the `NFC` class, and holds the library constants, C structs, and attaches the following functions:

- `PN532_ReadPassiveTarget` as `read_passive_target`
- `PN532_SamConfiguration` as `sam_configuration`
- `PN532_GetFirmwareVersion` as `get_firmware_version`
- `PN532_MifareClassicAuthenticateBlock` as `mifare_authenticate_block`
- `PN532_MifareClassicReadBlock` as `mifare_read_block`
- `PN532_MifareClassicWriteBlock` as `mifare_write_block`
- `PN532_Ntag2xxReadBlock` as `ntag_read_block`
- `PN532_Ntag2xxWriteBlock` as `ntag_write_block`
- `PN532_SPI_Init` as `spi_init`
- `PN532_SPI_WaitReady` as `spi_wait_ready`

#### PN532Struct
The `PN532Struct` class is an FFI struct with a layout defined by the C library.

#### DataBuffer
The `DataBuffer` class is an FFI struct, with a single element called 'buffer', an array of 255 uint8's. `DataBuffer` also has a few ease of use methods

```ruby
require 'taptag/pn532/structs'

bf = Taptag::PN532::DataBuffer.new

# Converts to a ruby array
bf.to_a # => [0, 0, 0...]

# And can be accessed directly
bf[0] # => 0

# You can reset the values
bf.reset.to_a # => [0, 0...]

# Or set them to a known value
bf.set([255, 255, 255]).to_a # => [255, 255, 255, 0...]

# You can also get the length excluding zeroes
bf.nonzero_length # => 3
```

## Testing

Programs that deal with external requirements are [troublesome](https://eev.ee/blog/2016/08/22/testing-for-people-who-hate-testing/#troublesome-cases) to test. Testing taptag thoroughly requires physical setup, and needs to be run on the actual hardware, so a test runner is included which prompts the user for cues like adding / removing a tag from the NFC HAT and runs the extended tests. You can run it by navigating to the base folder, and running `spec/test_runner.rb` to select the test scenarios to run. The tests are standard RSpec examples, and can be run independently instead if desired.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jtp184/taptag

