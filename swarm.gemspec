# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "swarm-agent"
  spec.version = "0.1.0"
  spec.authors = ["kiyo-e"]
  spec.email = [""]

  spec.summary = "A Ruby library for managing OpenAI chat completions with function calling support"
  spec.description = "Swarm is a Ruby library that provides a simple interface for managing OpenAI chat completions with function calling support. It includes features like streaming responses, context management, and function execution."
  spec.homepage = "https://github.com/kiyo-e/swarm"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

spec.metadata["homepage_uri"] = spec.homepage
spec.metadata["changelog_uri"] = "https://github.com/kiyo-e/swarm/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{lib,exe}/**/*") + %w[LICENSE.txt README.md]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby-openai", "~> 7.0.0"
  spec.add_dependency "json", "~> 2.6"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
