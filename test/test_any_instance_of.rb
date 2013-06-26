
require 'muack/test'

describe Muack::AnyInstanceOf do
  klass = Class.new{ def f; 0; end }

  should 'mock any_instance_of' do
    any_instance_of(klass){ |instance| mock(instance).say{ true } }
    obj = klass.new
    obj.say              .should.eq true
    obj.respond_to?(:say).should.eq true
    Muack.verify         .should.eq true
    obj.respond_to?(:say).should.eq false
  end

  should 'proxy any_instance_of' do
    any_instance_of(klass){ |instance| mock(instance).f.proxy }
    obj = klass.new
    obj.f       .should.eq 0
    Muack.verify.should.eq true
    obj.f       .should.eq 0
  end

  should 'proxy any_instance_of with a block' do
    any_instance_of(klass){ |instance| mock(instance).f{ |i| i+1 }.proxy }
    obj = klass.new
    obj.f       .should.eq 1
    Muack.verify.should.eq true
    obj.f       .should.eq 0
  end

  should 'proxy with multiple any_instance_of call' do
    any_instance_of(klass){ |instance| mock(instance).f{ |i| i+1 }.proxy }
    any_instance_of(klass){ |instance| mock(instance).f{ |i| i+2 }.proxy }
    obj = klass.new
    obj.f.should.eq 1
    obj.f.should.eq 2
    Muack.verify.should.eq true
    obj.f.should.eq 0
  end

  should 'mock with multiple any_instance_of call' do
    any_instance_of(klass){ |inst| mock(inst).f(is_a(Fixnum)){ |i| i+1 } }
    any_instance_of(klass){ |inst| mock(inst).f(is_a(Fixnum)){ |i| i+2 } }
    obj = klass.new
    obj.f(2).should.eq 3
    obj.f(2).should.eq 4
    Muack.verify.should.eq true
    obj.f.should.eq 0
  end

  should 'stub proxy with any_instance_of and spy' do
    any_instance_of(klass){ |inst| stub(inst).f{ |i| i+3 }.proxy }
    obj = klass.new
    obj.f.should.eq 3
    obj.f.should.eq 3
    spy(any_instance_of(klass)).f.times(2)
    Muack.verify.should.eq true
    obj.f.should.eq 0
  end
end
