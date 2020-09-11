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
blocks = Taptag::Encoder.call(prompt.ask('Enter the data to write to the card:'))

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
dump_spin = spinner['Writing tag...']

# Run the spinner and write the data
dump_spin.run do |spin|
  Taptag::NFC.write_mifare_card(blocks)
  spin.success('Done!'.green)
end
