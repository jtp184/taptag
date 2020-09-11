#!/usr/bin/env ruby
# frozen_string_literal: true

require 'taptag'
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org/'

  gem 'colorize'
  gem 'tty-spinner'
  gem 'tty-box'
end

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

# Fun randomized color display
byte_colors = Hash.new { |hsh, key| hsh[key] = %i[red yellow cyan blue green magenta].sample }
byte_colors[0] = :light_black

# Formats the bytes into hex and colorizes them
format_bytes = proc do |byte|
  s = byte.to_s(16)
  s.chars.one? ? "0#{s.upcase}".send(byte_colors[s]) : s.upcase.send(byte_colors[s])
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
bytes = nil

# Run the spinner and read the data
dump_spin.run do |spin|
  bytes = Taptag::NFC.read_mifare_card
  spin.success('Done!'.green)
end

# Unencode and display
box = TTY::Box.frame(width: 30, height: 10, title: { top_left: 'DATA' }, padding: 1) do
  Taptag::Encoder[bytes]
end

puts box

exit
