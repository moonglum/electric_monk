# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "electric_monk/version"

Gem::Specification.new do |spec|
  spec.name          = "electric_monk"
  spec.version       = ElectricMonk::VERSION
  spec.authors       = ["Lucas Dohmen"]
  spec.email         = ["lucas@dohmen.io"]

  spec.summary       = %q{An assistant for your projects directory}
  spec.description   = %q{Manage your git-based projects with a CLI: It assumes that you have a directory with your repositories and will clone/update them for you and report their status.}
  spec.homepage      = "https://github.com/moonglum/electric_monk"
  spec.license       = "GPL-3.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "toml-rb"
  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-around"
end
