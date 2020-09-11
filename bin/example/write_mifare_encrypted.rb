#!/usr/bin/env ruby
# frozen_string_literal: true

require 'taptag'
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org/'

  gem 'colorize'
  gem 'tty-prompt'
  gem 'tty-spinner'
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
  key(:data).ask('Enter the data to write to the card:')

  key(:vector_mtd).select('Where to store vector?', %w[disk block])
  key(:key_mtd).select('Where to store key?', %w[disk block])

  key(:algorithm).ask('Encryption algorithm:', default: 'AES-128-CBC')
end

# Encrypt the data
encrypted_data = Taptag::Encrypter.encrypt(info[:data], info)

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

encrypted_string = encrypted_data[:data]

# Depending on user choice, prepend the encrypted data string with the vector or string
%i[vector key].each do |msig|
  case info[:"#{msig}_mtd"]
  when 'disk'
    store_loc = prompt.ask("Where to store #{msig} file?", default: './')
    fname = "#{msig}_#{cuid.map(&format_bytes).join}.bin"

    File.open(store_loc + fname, 'w+') do |f|
      f << encrypted_data[msig]
    end
    puts "Saved file #{(store_loc + fname).green}"
  when 'block'
    encrypted_string.prepend(encrypted_data[msig])
  end
end

# Encode the encrypted string into blocks
blocks = Taptag::Encoder[encrypted_string]

# Spinner for card data writing
dump_spin = spinner['Writing tag...']

# Run the spinner and write the data
dump_spin.run do |spin|
  Taptag::NFC.write_mifare_card(blocks)
  spin.success('Done!'.green)
end
