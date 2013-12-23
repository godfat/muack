# -*- encoding: utf-8 -*-
# stub: muack 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "muack"
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lin Jen-Shin (godfat)"]
  s.date = "2013-12-24"
  s.description = "Muack -- Yet another mocking library.\n\nBasically it's an [RR][] clone, but much faster under heavy use.\nIt's 32x times faster (750s vs 23s) for running [Rib][] tests.\n\n[RR]: https://github.com/rr/rr\n[Rib]: https://github.com/godfat/rib"
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
  "task/.gitignore",
  "task/gemgem.rb",
  "test/test_any_instance_of.rb",
  "test/test_mock.rb",
  "test/test_modifier.rb",
  "test/test_proxy.rb",
  "test/test_readme.rb",
  "test/test_satisfy.rb",
  "test/test_stub.rb"]
  s.homepage = "https://github.com/godfat/muack"
  s.licenses = ["Apache License 2.0"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.1.11"
  s.summary = "Muack -- Yet another mocking library."
  s.test_files = [
  "test/test_any_instance_of.rb",
  "test/test_mock.rb",
  "test/test_modifier.rb",
  "test/test_proxy.rb",
  "test/test_readme.rb",
  "test/test_satisfy.rb",
  "test/test_stub.rb"]
end
