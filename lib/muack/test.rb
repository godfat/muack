
require 'pork/auto'
require 'muack'

Pork::Suite.include(Muack::API)

Obj = Object.new
Str = 'Moo'
def Obj.inspect
  'obj'
end
def Obj.private
  'pri'
end
def Obj.aloha a=0, b=1
  [a, b]
end
Obj.singleton_class.__send__(:private, :private)

Muack::EnsureReset = lambda{
  [Obj, Str].each do |o|
    o.methods.select{ |m|
      m.to_s.start_with?('__muack_mock') || m.to_s.start_with?('say')
    }.should.empty?
  end
}
