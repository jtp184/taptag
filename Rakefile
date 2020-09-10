require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

RDOC_EXCLUDE = %w[
  bin/setup
  bin/console
  Gemfile
  Gemfile.lock
  Rakefile
  tmp
  docs
  spec
  wpa_supplicant.conf
].freeze

task default: :spec

task :docs do
  rd_exclude = RDOC_EXCLUDE.map { |r| "--exclude=#{r}" }.join(' ')

  sh "rdoc --output=docs --format=hanna --all --main=README.md #{rd_exclude}"
end

task :doc_check do
  rd_exclude = RDOC_EXCLUDE.map { |r| "--exclude=#{r}" }.join(' ')

  sh "rdoc -C --output=docs --format=hanna --all --main=README.md #{rd_exclude}"
end
