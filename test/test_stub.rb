
require 'muack/test'

describe Muack::Stub do
  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'stub with regular method' do
      stub(Obj).say{ 'goo' }
      3.times{ Obj.say.should.eq 'goo' }
    end

    should 'stub with any arguments' do
      stub(Str).say{ Str.sub('M', 'H') }.with_any_args
      Str.say      .should.eq 'Hoo'
      Str.say(0)   .should.eq 'Hoo'
      Str.say(0, 1).should.eq 'Hoo'
      Str.say('  ').should.eq 'Hoo'
    end

    should 'accept block form' do
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

    should 'raise Muack::Unexpected error if passing unexpected argument' do
      stub(Obj).say(true){ 'boo' }
      begin
        Obj.say(false)
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq 'obj.say(true)'
        e.was     .should.eq 'obj.say(false)'
        e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
      end
    end

    should 'give all alternatives' do
      stub(Obj).say(0){ 'boo' }
      stub(Obj).say(1){ 'moo' }
      begin
        Obj.say(false)
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq "obj.say(0)\n      or: obj.say(1)"
        e.was     .should.eq 'obj.say(false)'
        e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
      end
    end
  end
end
