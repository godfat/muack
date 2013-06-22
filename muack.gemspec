# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "muack"
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lin Jen-Shin (godfat)"]
  s.date = "2013-06-23"
  s.description = "Muack -- Yet Another Mocking Library\n\nBasically it's an RR clone."
  s.email = ["godfat (XD) godfat.org"]
  s.files = [
  ".gitmodules",
  ".travis.yml",
  "Gemfile",
  "README.md",
  "Rakefile",
  "lib/muack.rb",
  "lib/muack/failure.rb",
  "lib/muack/matcher.rb",
  "lib/muack/mock.rb",
  "lib/muack/session.rb",
  "lib/muack/stub.rb",
  "lib/muack/test.rb",
  "lib/muack/version.rb",
  "muack.gemspec",
  "task/.gitignore",
  "task/gemgem.rb",
  "test/test_matcher.rb",
  "test/test_mock.rb",
  "test/test_readme.rb"]
  s.homepage = "https://github.com/godfat/muack"
  s.licenses = ["Apache License 2.0"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "Muack -- Yet Another Mocking Library"
  s.test_files = [
  "test/test_matcher.rb",
  "test/test_mock.rb",
  "test/test_readme.rb"]
end
