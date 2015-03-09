
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

    would 'inspect' do
      spy( Obj).inspect.should.eq "Muack::API.spy(obj)"
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

    would 'work with spy' do
      stub(Obj).say{0}
      Obj.say.should.eq 0
       spy(Obj).say
    end

    would 'work with spy twice' do
      stub(Obj).say{}
      2.times{ Obj.say.should.eq nil }
       spy(Obj).say.times(2)
    end

    would 'work with spy spy' do
      stub(Obj).say{}
      2.times{ Obj.say.should.eq nil }
      2.times{ spy(Obj).say }
    end

    would 'work with call spy and call spy' do
      stub(Obj).say{}
      2.times do
        Obj.say.should.eq nil
        spy(Obj).say
      end
    end

    would 'verify spy arguments' do
      stub(Obj).say(1){|a|a}
      Obj.say(1).should.eq 1
       spy(Obj).say(1)
    end

    would 'properly verify spy arguments' do
      stub(Obj).say(is_a(String)){|a|a}
      Obj.say('Hi!').should.eq 'Hi!'
       spy(Obj).say(is_a(String))
    end

    would 'ignore messages spies not interested' do
      stub(Obj).saya{0}
      stub(Obj).sayb{1}
      Obj.saya.should.eq 0
      Obj.sayb.should.eq 1
       spy(Obj).saya
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

    would 'raise Expected if the spy is not satisfied' do
      stub(Obj).say{}
       spy(Obj).say
      e = should.raise(Muack::Expected){ Muack.verify }
      e.expected      .should.eq 'obj.say()'
      e.expected_times.should.eq 1
      e.actual_times  .should.eq 0
      e.message       .should.eq "\nExpected: obj.say()\n  " \
                                 "called 1 times\n but was 0 times."
    end

    would 'raise Expected if the spy is not satisfied enough' do
      stub(Obj).say{}
      Obj.say
       spy(Obj).say(0)
      e = should.raise(Muack::Unexpected){ Muack.verify }
      e.expected.should.eq "obj.say(0)"
      e.was     .should.eq 'obj.say()'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'show correct times for under satisfaction' do
      stub(Obj).say{}
      2.times{ Obj.say }
       spy(Obj).say.times(3)
      e = should.raise(Muack::Expected){ Muack.verify }
      e.expected      .should.eq 'obj.say()'
      e.expected_times.should.eq 3
      e.actual_times  .should.eq 2
      e.message       .should.eq "\nExpected: obj.say()\n  " \
                                 "called 3 times\n but was 2 times."
    end

    would 'show correct times for over satisfaction' do
      stub(Obj).say{}
      2.times{ Obj.say }
       spy(Obj).say
      e = should.raise(Muack::Expected){ Muack.verify }
      e.expected      .should.eq 'obj.say()'
      e.expected_times.should.eq 1
      e.actual_times  .should.eq 2
      e.message       .should.eq "\nExpected: obj.say()\n  " \
                                 "called 1 times\n but was 2 times."
    end
  end
end
