
begin
  require "#{__dir__}/task/gemgem"
rescue LoadError
  sh 'git submodule update --init'
  exec Gem.ruby, '-S', $PROGRAM_NAME, *ARGV
end

Gemgem.init(__dir__) do |s|
  require 'muack/version'
  s.name    = 'muack'
  s.version = Muack::VERSION
  %w[].each{ |g| s.add_runtime_dependency(g) }
end
