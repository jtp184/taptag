require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

# By default don't assume we have the HAT, just run the tests we need to
RSpec::Core::RakeTask.new(:test) do |t|
  t.rspec_opts = '--tag ~@hardware'
end

RSpec::Core::RakeTask.new(:test_all)

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

task default: :test

task :docs do
  rd_exclude = RDOC_EXCLUDE.map { |r| "--exclude=#{r}" }.join(' ')

  sh "rdoc --output=docs --format=hanna --all --main=README.md #{rd_exclude}"
end

task :doc_check do
  rd_exclude = RDOC_EXCLUDE.map { |r| "--exclude=#{r}" }.join(' ')

  sh "rdoc -C --output=docs --format=hanna --all --main=README.md #{rd_exclude}"
end

task :reinstall do
  needs_sudo = Gem.platforms.last.os == 'linux'
  sh "#{needs_sudo ? 'sudo ' : ''}gem uninstall taptag"
  sh "#{needs_sudo ? 'sudo ' : ''}rake install"
end
