require_relative 'lib/taptag/version'

Gem::Specification.new do |spec|
  spec.name          = 'Taptag'
  spec.version       = Taptag::VERSION
  spec.authors       = ['Justin Piotroski']
  spec.email         = ['justin.piotroski@gmail.com']

  spec.summary       = "A Gem for communicating with Waveshare's NFC HAT"
  spec.homepage      = 'https://github.com/jtp184/taptag'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'ffi', '~> 1.13.1'
  spec.add_runtime_dependency 'openssl', '~> 2.1.2'
  spec.add_development_dependency 'pry', '~> 0.13.1'
end
