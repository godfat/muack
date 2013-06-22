
require 'muack/test'

describe Muack::Mock do
  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'mock with regular method' do
      mock(Obj).say(true){ 'boo' }
      Obj.say(true).should.eq 'boo'
    end

    should 'mock with is_a matcher' do
      mock(Str).say(is_a(String)){ |arg| arg.reverse }
      Str.say('Foo').should.eq 'ooF'
    end

    should 'stub with regular method' do
      stub(Obj).say{ 'goo' }
      3.times{ Obj.say.should.eq 'goo' }
    end

    should 'mock twice' do
      mock(Obj).say(true){ Obj.saya }
      mock(Obj).saya{ 'coo' }
      Obj.say(true).should.eq 'coo'
    end

    should 'mock external object' do
      mock(Str).say{ Str.sub('M', 'H') }
      Str.say.should.eq 'Hoo'
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.verify.should.eq false
      Muack::EnsureReset.call
    end

    should 'raise Muack::Unexpected error if passing unexpected argument' do
      mock(Obj).say(true){ 'boo' }
      begin
        Obj.say(false)
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq 'obj.say(true)'
        e.was     .should.eq 'obj.say(false)'
      end
    end
  end
end
