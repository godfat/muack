
require 'muack/test'

describe Muack do
  before do
    Muack.reset
  end

  should 'mock with regular method call' do
    moo = mock.moo(true){ 'boo' }
    moo.moo(true).should.eq 'boo'
    Muack.verify.should.eq true
  end

  should 'raise Muack::Unexpected error if passing unexpected argument' do
    moo = mock.moo(true){ 'boo' }
    obj = moo.__mock_object
    def obj.inspect
      'moo'
    end
    begin
      moo.moo(false).should.eq 'boo'
      'never'.should.eq 'reach'
    rescue Muack::Unexpected => e
      e.expected.should.eq 'moo.moo(true)'
      e.was     .should.eq 'moo.moo(false)'
      Muack.verify.should.eq false
    end
  end

  should 'mock chain' do
    moo = mock
    moo.moo(true){ moo.boo }.mock.boo{ 'coo' }
    moo.moo(true).should.eq 'coo'
    Muack.verify.should.eq true
  end

  should 'mock external object' do
    moo = mock('Moo')
    moo.sleep{ moo.sub('M', 'H') }
    moo.sleep.should.eq 'Hoo'
    Muack.verify.should.eq true
  end

  should 'stub regular method' do
    moo = stub.foo{ 'goo' }
    3.times{ moo.foo.should.eq 'goo' }
    Muack.verify.should.eq true
  end

  should 'accept matcher' do
    moo = mock('Moo').say(is_a(String)){ |arg| arg.reverse }
    moo.say('Foo').should.eq 'ooF'
    Muack.verify.should.eq true
  end
end
