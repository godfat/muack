
require 'pork/auto'
require 'muack'

Pork::Suite.include(Muack::API)

Str = String.new('Moo')
class Cls
  def inspect
    'obj'
  end
  def aloha a=0, b=1
    [a, b]
  end
end
Obj = Cls.new
def Obj.private
  'pri'
end
Obj.singleton_class.__send__(:private, :private)

Muack::EnsureReset = lambda{
  [Obj, Str].each do |o|
    o.methods.select{ |m|
      m.to_s.start_with?('__muack_mock') || m.to_s.start_with?('say')
    }.should.empty?
  end
}
