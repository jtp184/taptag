#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'bundler/inline'
require 'pp'

gemfile do
  source 'https://rubygems.org/'

  gem 'colorize'
  gem 'tty-prompt'
  gem 'tty-spinner'
  gem 'tty-pager'
  gem 'pry'
end

# Set up the prompt for user input
prompt = TTY::Prompt.new(
  interrupt: -> { puts 'x'.light_black; puts 'Goodbye'.red; abort }
)

# Create the spinner factory
spinner = proc do |str|
  TTY::Spinner.new(
    "[:spinner] #{str}",
    success_mark: '✅',
    error_mark: '❗️',
    frames: '🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🕐🕑',
    interval: 12
  )
end

# Run RSpec in a subshell, json format for parsing
rspec = proc do |cmd|
  specs = JSON.parse(`rspec -fj #{cmd}`.split('Coverage')[0])

  specs['examples'].map do |ex|
    [ex['full_description'], ex['status'] == 'passed']
  end.to_h
end

# Test scenario choices
test_options = {
  software: 'Software-only tests',
  typeless: 'Tag-type independent hardware tests',
  mifare_present: 'Mifare card (present)',
  mifare_absent: 'Mifare card (absent)',
  ntag_present: 'Ntag card (present)',
  ntag_absent: 'Ntag card (absent)'
}

# Ask for which tasks to run
tasks = prompt.multi_select('What test groups to run?', test_options.values)
              .map { |t| test_options.key(t) }

test_results = {}

spin = spinner['Running Tests...']
spin.auto_spin

test_results.merge!(rspec['--tag ~@hardware']) if tasks.include?(:software)
test_results.merge!(rspec['--tag ~@ntag --tag ~@mifare']) if tasks.include?(:typeless)

if tasks.include?(:mifare_present)
  spin.pause
  puts
  puts 'Please place a mifare card on the NFC hat and do not remove it until prompted'.yellow
  puts 'Press enter to continue...'.light_black
  gets

  spin.resume
  test_results.merge! rspec['spec/mifare_card_present.rb']
end

if tasks.include?(:mifare_absent)
  spin.pause
  puts
  puts 'Please ensure there is NOT a card on the NFC hat'.yellow
  puts 'Press enter to continue...'.light_black
  gets

  spin.resume
  test_results.merge! rspec['spec/mifare_card_absent.rb']
end

if tasks.include?(:ntag_present)
  spin.pause
  puts
  puts 'Please place a ntag card on the NFC hat and do not remove it until prompted'.yellow
  puts 'Press enter to continue...'.light_black
  gets

  spin.resume
  test_results.merge! rspec['spec/ntag_card_present.rb']
end

if tasks.include?(:ntag_absent)
  spin.pause
  puts
  puts 'Please ensure there is NOT a card on the NFC hat'.yellow
  puts 'Press enter to continue...'.light_black
  gets

  spin.resume
  test_results.merge! rspec['spec/ntag_card_absent.rb']
end

spin.success('...Done!')

if test_results.values.all?(true)
  puts 'All tests have passed!'.green
  exit_with = :exit
else
  puts "#{test_results.values.count(true)} / #{test_results.values.count} tests have passed."
  exit_with = :abort
end

# Offer to show test outcomes
if prompt.yes?('Inspect results?')
  tst = test_results.map do |k, v|
    "#{k.cyan}\n\t#{v ? 'Passed'.green : 'Failed'.red}"
  end.join("\n")

  TTY::Pager.new(command: ['bat --file-name TEST_RESULTS', 'less -R'])
            .page(tst)
end

case exit_with
when :exit
  exit
when :abort
  abort
end
