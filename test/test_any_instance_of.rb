
require 'muack/test'

describe Muack::AnyInstanceOf do
  should 'mock any_instance_of' do
    klass = Class.new
    any_instance_of(klass){ |instance| mock(instance).say{ true } }
    obj = klass.new
    obj.say              .should.eq true
    obj.respond_to?(:say).should.eq true
    Muack.verify         .should.eq true
    obj.respond_to?(:say).should.eq false
  end

  should 'proxy any_instance_of' do
    klass = Class.new{ def f; true; end }
    any_instance_of(klass){ |instance| proxy(instance).f }
    obj = klass.new
    obj.f.should.eq true
    Muack.verify.should.eq true
  end
end
