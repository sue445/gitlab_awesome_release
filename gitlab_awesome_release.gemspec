# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gitlab_awesome_release/version"

Gem::Specification.new do |spec|
  spec.name          = "gitlab_awesome_release"
  spec.version       = GitlabAwesomeRelease::VERSION
  spec.authors       = ["sue445"]
  spec.email         = ["sue445@sue445.net"]

  spec.summary       = "Generate changelog from tags and MergeRequests on GitLab"
  spec.description   = "Generate changelog from tags and MergeRequests on GitLab"
  spec.homepage      = "https://gitlab.com/sue445/gitlab_awesome_release"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1.0"

  spec.add_dependency "dotenv"
  spec.add_dependency "gitlab", ">= 4.0.0"
  spec.add_dependency "thor"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "onkcop", "0.47.1.0"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-temp_dir"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "yard"
end
