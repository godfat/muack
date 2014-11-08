# -*- encoding: utf-8 -*-
# stub: muack 1.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "muack"
  s.version = "1.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Lin Jen-Shin (godfat)"]
  s.date = "2014-11-08"
  s.description = "Muack -- A fast, small, yet powerful mocking library.\n\nInspired by [RR][], and it's 32x times faster (750s vs 23s) than RR\nfor running [Rib][] tests.\n\n[RR]: https://github.com/rr/rr\n[Rib]: https://github.com/godfat/rib"
  s.email = ["godfat (XD) godfat.org"]
  s.files = [
  ".gitignore",
  ".gitmodules",
  ".travis.yml",
  "CHANGES.md",
  "Gemfile",
  "LICENSE",
  "README.md",
  "Rakefile",
  "lib/muack.rb",
  "lib/muack/any_instance_of.rb",
  "lib/muack/block.rb",
  "lib/muack/coat.rb",
  "lib/muack/definition.rb",
  "lib/muack/error.rb",
  "lib/muack/failure.rb",
  "lib/muack/mock.rb",
  "lib/muack/modifier.rb",
  "lib/muack/satisfy.rb",
  "lib/muack/session.rb",
  "lib/muack/spy.rb",
  "lib/muack/stub.rb",
  "lib/muack/test.rb",
  "lib/muack/version.rb",
  "muack.gemspec",
  "task/README.md",
  "task/gemgem.rb",
  "test/test_any_instance_of.rb",
  "test/test_coat.rb",
  "test/test_from_readme.rb",
  "test/test_mock.rb",
  "test/test_modifier.rb",
  "test/test_proxy.rb",
  "test/test_satisfy.rb",
  "test/test_stub.rb"]
  s.homepage = "https://github.com/godfat/muack"
  s.licenses = ["Apache License 2.0"]
  s.rubygems_version = "2.4.2"
  s.summary = "Muack -- A fast, small, yet powerful mocking library."
  s.test_files = [
  "test/test_any_instance_of.rb",
  "test/test_coat.rb",
  "test/test_from_readme.rb",
  "test/test_mock.rb",
  "test/test_modifier.rb",
  "test/test_proxy.rb",
  "test/test_satisfy.rb",
  "test/test_stub.rb"]
end
