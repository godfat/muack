# -*- encoding: utf-8 -*-
# stub: muack 1.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "muack".freeze
  s.version = "1.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Lin Jen-Shin (godfat)".freeze]
  s.date = "2022-12-29"
  s.description = "Muack -- A fast, small, yet powerful mocking library.\n\nInspired by [RR][], and it's 32x times faster (750s vs 23s) than RR\nfor running [Rib][] tests.\n\n[RR]: https://github.com/rr/rr\n[Rib]: https://github.com/godfat/rib".freeze
  s.email = ["godfat (XD) godfat.org".freeze]
  s.files = [
  ".gitignore".freeze,
  ".gitlab-ci.yml".freeze,
  ".gitmodules".freeze,
  "CHANGES.md".freeze,
  "Gemfile".freeze,
  "LICENSE".freeze,
  "README.md".freeze,
  "Rakefile".freeze,
  "lib/muack.rb".freeze,
  "lib/muack/any_instance_of.rb".freeze,
  "lib/muack/block.rb".freeze,
  "lib/muack/coat.rb".freeze,
  "lib/muack/definition.rb".freeze,
  "lib/muack/error.rb".freeze,
  "lib/muack/failure.rb".freeze,
  "lib/muack/mock.rb".freeze,
  "lib/muack/modifier.rb".freeze,
  "lib/muack/satisfying.rb".freeze,
  "lib/muack/session.rb".freeze,
  "lib/muack/spy.rb".freeze,
  "lib/muack/stub.rb".freeze,
  "lib/muack/test.rb".freeze,
  "lib/muack/version.rb".freeze,
  "muack.gemspec".freeze,
  "task/README.md".freeze,
  "task/gemgem.rb".freeze,
  "test/test_any_instance_of.rb".freeze,
  "test/test_coat.rb".freeze,
  "test/test_from_readme.rb".freeze,
  "test/test_keyargs.rb".freeze,
  "test/test_mock.rb".freeze,
  "test/test_modifier.rb".freeze,
  "test/test_prepend.rb".freeze,
  "test/test_proxy.rb".freeze,
  "test/test_satisfying.rb".freeze,
  "test/test_spy.rb".freeze,
  "test/test_stub.rb".freeze,
  "test/test_visibility.rb".freeze]
  s.homepage = "https://github.com/godfat/muack".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Muack -- A fast, small, yet powerful mocking library.".freeze
  s.test_files = [
  "test/test_any_instance_of.rb".freeze,
  "test/test_coat.rb".freeze,
  "test/test_from_readme.rb".freeze,
  "test/test_keyargs.rb".freeze,
  "test/test_mock.rb".freeze,
  "test/test_modifier.rb".freeze,
  "test/test_prepend.rb".freeze,
  "test/test_proxy.rb".freeze,
  "test/test_satisfying.rb".freeze,
  "test/test_spy.rb".freeze,
  "test/test_stub.rb".freeze,
  "test/test_visibility.rb".freeze]
end
