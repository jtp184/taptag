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
  next unless cuid

  spinner.success('Found!'.green)

  cuid.map! do |byte|
    s = byte.to_s(16)
    s.chars.one? ? "0#{s.upcase}" : s.upcase
  end

  puts "[🏷️] #{cuid.join(' ')}"
  exit
end
