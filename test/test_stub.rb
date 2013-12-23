
require 'muack/test'

describe Muack::Stub do
  should 'raise StubHasNoTimes with stub(obj).f.times(0)' do
    lambda{ stub(Obj).f.times(0) }.should.raise(Muack::StubHasNoTimes)
  end

  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'inspect' do
      stub(Obj).inspect.should.eq "Muack::API.stub(obj)"
    end

    should 'inspect' do
      spy( Obj).inspect.should.eq "Muack::API.spy(obj)"
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

    should 'work with spy' do
      stub(Obj).say{0}
      Obj.say.should.eq 0
      spy(Obj).say
    end

    should 'work with spy twice' do
      stub(Obj).say{}
      2.times{ Obj.say.should.eq nil }
      spy(Obj).say.times(2)
    end

    should 'work with spy spy' do
      stub(Obj).say{}
      2.times{ Obj.say.should.eq nil }
      2.times{ spy(Obj).say }
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.reset
      Muack::EnsureReset.call
    end

    should 'raise Unexpected error if passing unexpected argument' do
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

    should 'raise Expected if the spy is not satisfied' do
      stub(Obj).say{}
      spy( Obj).say
      begin
        Muack.verify
        'never'.should.eq 'reach'
      rescue Muack::Expected => e
        e.expected      .should.eq 'obj.say()'
        e.expected_times.should.eq 1
        e.actual_times  .should.eq 0
        e.message       .should.eq "\nExpected: obj.say()\n  " \
                                   "called 1 times\n but was 0 times."
      end
    end

    should 'raise Expected if the spy is not satisfied enough' do
      stub(Obj).say{}
      Obj.say
      spy( Obj).say(0)
      begin
        Muack.verify
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq "obj.say(0)"
        e.was     .should.eq 'obj.say()'
        e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
      end
    end

    should 'show correct times for under satisfaction' do
      stub(Obj).say{}
      2.times{ Obj.say }
      spy( Obj).say.times(3)
      begin
        Muack.verify
        'never'.should.eq 'reach'
      rescue Muack::Expected => e
        e.expected      .should.eq 'obj.say()'
        e.expected_times.should.eq 3
        e.actual_times  .should.eq 2
        e.message       .should.eq "\nExpected: obj.say()\n  " \
                                   "called 3 times\n but was 2 times."
      end
    end

    should 'show correct times for over satisfaction' do
      stub(Obj).say{}
      2.times{ Obj.say }
      spy( Obj).say
      begin
        Muack.verify
        'never'.should.eq 'reach'
      rescue Muack::Expected => e
        e.expected      .should.eq 'obj.say()'
        e.expected_times.should.eq 1
        e.actual_times  .should.eq 2
        e.message       .should.eq "\nExpected: obj.say()\n  " \
                                   "called 1 times\n but was 2 times."
      end
    end
  end
end
