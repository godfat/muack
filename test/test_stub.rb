
require 'muack/test'

describe Muack::Stub do
  would 'raise StubHasNoTimes with stub(obj).f.times(0)' do
    lambda{ stub(Obj).f.times(0) }.should.raise(Muack::StubHasNoTimes)
  end

  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    would 'inspect' do
      stub(Obj).inspect.should.eq "Muack::API.stub(obj)"
    end

    would 'stub with regular method' do
      stub(Obj).say{ 'goo' }
      3.times{ Obj.say.should.eq 'goo' }
    end

    would 'stub with any arguments' do
      stub(Str).say{ Str.sub('M', 'H') }.with_any_args
      Str.say      .should.eq 'Hoo'
      Str.say(0)   .should.eq 'Hoo'
      Str.say(0, 1).should.eq 'Hoo'
      Str.say('  ').should.eq 'Hoo'
    end

    would 'pass the actual block' do
      stub(Obj).say{ |&block| block.call('Hi') }
      Obj.say{ |msg| msg }.should.eq 'Hi'
    end

    would 'accept block form' do
      stub(Obj){ |o| o.say{0}; o.saya{1} }
      Obj.saya.should.eq 1
      Obj.say .should.eq 0
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.reset
      Muack::EnsureReset.call
    end

    would 'raise Unexpected error if passing unexpected argument' do
      stub(Obj).say(true){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(false) }
      e.expected.should.eq 'obj.say(true)'
      e.was     .should.eq 'obj.say(false)'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'give all alternatives' do
      stub(Obj).say(0){ 'boo' }
      stub(Obj).say(1){ 'moo' }
      e = should.raise(Muack::Unexpected){ Obj.say(false) }
      e.expected.should.eq "obj.say(1)\n      or: obj.say(0)"
      e.was     .should.eq 'obj.say(false)'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end
  end
end
