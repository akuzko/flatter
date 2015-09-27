# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flatter/version'

Gem::Specification.new do |spec|
  spec.name          = "flatter"
  spec.version       = Flatter::VERSION
  spec.authors       = ["Artem Kuzko"]
  spec.email         = ["a.kuzko@gmail.com"]

  spec.summary       = %q{Deep object graph to a plain flat properties mapper.}
  spec.description   = %q{This library allows to map accessors and properties of deeply
    nested model graph to a plain mapper object with flexible behavior.}
  spec.homepage      = "https://github.com/akuzko/flatter"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 3.2"
  spec.add_dependency "activemodel"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov", ">= 0.9"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-nav"
end
