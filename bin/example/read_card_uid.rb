#!/usr/bin/env ruby
# frozen_string_literal: true

require 'taptag'
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org/'

  gem 'colorize'
  gem 'tty-spinner'
end

spinner = TTY::Spinner.new(
  '[:spinner] Waiting for Tag...',
  success_mark: '✅',
  error_mark: '❗️',
  frames: '🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🕐🕑',
  interval: 12
)

spinner.auto_spin

loop do
  cuid = Taptag::NFC.card_uid
  # Loop until the cuid is not nil
  next unless cuid

  spinner.success('Found!'.green)

  # Map it to hex for easier presentation
  cuid.map! do |byte|
    s = byte.to_s(16).upcase
    s.chars.one? ? "0#{s}" : s
  end

  # Print it out and exit the loop
  puts "[🏷️] #{cuid.join(' ')}"
  exit
end
