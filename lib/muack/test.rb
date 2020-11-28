
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
  def bonjour a: 0, b: 1
    [a, b]
  end
  def ciao h={a: 0, b: 1}
    h.values_at(:a, :b)
  end
  module Prepend
    def prepend_aloha a=0, b=1
      [a, b]
    end
    def prepend_bonjour a: 0, b: 1
      [a, b]
    end
    def prepend_ciao h={a: 0, b: 1}
      h.values_at(:a, :b)
    end
  end
  prepend Prepend
end
Obj = Cls.new
class << Obj
  private def private
    'pri'
  end

  def single_aloha a=0, b=1
    [a, b]
  end
  def single_bonjour a: 0, b: 1
    [a, b]
  end
  def single_ciao h={a: 0, b: 1}
    h.values_at(:a, :b)
  end
end

Muack::EnsureReset = lambda{
  [Obj, Str].each do |o|
    o.methods.select{ |m|
      m.to_s.start_with?('__muack_mock') || m.to_s.start_with?('say')
    }.should.empty?
  end
}
