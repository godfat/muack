
require 'bacon'
require 'muack'

Bacon.summary_on_exit
include Muack::API

Obj = Object.new
Str = 'Moo'
def Obj.inspect
  'obj'
end

Muack::EnsureReset = lambda{
  [Obj, Str].each do |o|
    o.methods.select{ |m|
      m.to_s.start_with?('__muack_mock') || m.to_s.start_with?('say')
    }.should.empty
  end
}

module Kernel
  def eq? rhs
    self == rhs
  end
end
