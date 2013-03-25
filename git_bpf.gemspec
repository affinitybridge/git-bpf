# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git_bpf/version'

Gem::Specification.new do |spec|
  spec.name          = "git_bpf"
  spec.version       = GitBpf::VERSION
  spec.authors       = ["tnightingale"]
  spec.email         = ["tom@affinitybridge.com"]
  spec.description   = %q{A collection of commands to help with implementing the branch-per-feature git development workflow.}
  spec.summary       = %q{Git branch-per-feature helper commands.}
  spec.homepage      = "https://github.com/affinitybridge/git-bpf"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
