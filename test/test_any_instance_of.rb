
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
end
