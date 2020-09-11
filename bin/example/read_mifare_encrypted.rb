#!/usr/bin/env ruby
# frozen_string_literal: true

require 'taptag'
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org/'

  gem 'colorize'
  gem 'tty-prompt'
  gem 'tty-spinner'
  gem 'tty-box'
  gem 'pry'
end

# Set up the prompt for user input
prompt = TTY::Prompt.new(
  interrupt: -> { puts 'x'.light_black; puts 'Goodbye'.red; abort }
)

# Set up a spinner factory
spinner = proc do |str|
  TTY::Spinner.new(
    "[:spinner] #{str}",
    success_mark: '✅',
    error_mark: '❗️',
    frames: '🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🕐🕑',
    interval: 12
  )
end

# Formats the bytes into hex and colorizes them
format_bytes = proc do |byte|
  s = byte.to_s(16).upcase
  s.chars.one? ? "0#{s}" : s
end

# Request user input
info = prompt.collect do
  key(:key_mtd).select('Where is the key stored?', %w[disk block])
  key(:vector_mtd).select('Where is the vector stored?', %w[disk block])

  key(:algorithm).ask('Encryption algorithm:', default: 'AES-128-CBC')
end

# Spinner for card uid acquisition
uid_spin = spinner['Waiting for tag...']
cuid = nil

uid_spin.auto_spin

# Loop until card uid is acquired
loop do
  cuid = Taptag::NFC.card_uid
  next unless cuid

  uid_spin.success('Found!'.green)
  break
end

# Display uid
puts "[🏷️] #{cuid.map(&format_bytes).join(' ')}"

# Spinner for card data reading
dump_spin = spinner['Reading tag...']
blocks = nil
# Run the spinner and write the data
dump_spin.run do |spin|
  blocks = Taptag::NFC.read_mifare_card
  spin.success('Done!'.green)
end

# Depending on user choice, prepend the encrypted data string with the vector or string
e = %i[key vector].map.with_index do |msig, x|
  next msig, case info[:"#{msig}_mtd"]
             when 'disk'
               default_fname = "#{msig}_#{cuid.map(&format_bytes).join}.bin"

               floc = if File.exist?(default_fname)
                        default_fname
                      else
                        prompt.ask("Where to find #{msig} file?", default: "./tmp/#{default_fname}")
                      end

               File.read(floc)
             when 'block'
               mf_blks = Taptag::Encoder.writable_mifare_blocks
               blocks[mf_blks[x]].last.map(&:chr).join
             end
end.to_h

encrypted_string = Taptag::Encoder[blocks]

e[:data] = if info[:key_mtd] == 'block' && info[:vector_mtd] == 'block'
             encrypted_string[32..-1]
           elsif info[:vector_mtd] == 'block' || info[:key_mtd] == 'block'
             encrypted_string[16..-1]
           else
             encrypted_string
           end

decrypted_string = Taptag::Encrypter.decrypt(e)

# Display decrypted string
box = TTY::Box.frame(width: 30, height: 10, title: { top_left: 'DATA' }, padding: 1) do
  decrypted_string
end

puts box
