
require 'muack/test'

describe Muack::Spy do
  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    would 'inspect' do
      spy( Obj).inspect.should.eq "Muack::API.spy(obj)"
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

    would 'not care about the order' do
      stub(Obj).say(is_a(Integer)){|i|i} # change to &:itself in the future
           Obj .say(1).should.eq 1
           Obj .say(2).should.eq 2
       spy(Obj).say(2)
       spy(Obj).say(1)
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.reset
      Muack::EnsureReset.call
    end

    would 'raise Expected if it is not satisfied' do
      stub(Obj).say{}
       spy(Obj).say
      e = should.raise(Muack::Expected){ Muack.verify }
      e.expected      .should.eq 'obj.say()'
      e.expected_times.should.eq 1
      e.actual_times  .should.eq 0
      e.message       .should.eq "\nExpected: obj.say()\n  " \
                                 "called 1 times\n but was 0 times."
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

    would 'raise Expected if arguments do not match' do
      stub(Obj).say(is_a(Integer)){}
           Obj .say(1)
       spy(Obj).say(0)
      e = should.raise(Muack::Unexpected){ Muack.verify }
      e.expected.should.eq "obj.say(0)"
      e.was     .should.eq 'obj.say(1)'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'raise Expected if arguments do not match, show original args' do
      stub(Obj).say(is_a(Integer)){}
           Obj .say(0)
           Obj .say(1)
           Obj .say(2)
       spy(Obj).say(within(1..1))
       spy(Obj).say(within(0..0))
      e = should.raise(Muack::Unexpected){ Muack.verify }
      e.expected.should.eq "obj.say(Muack::API.within(0..0))\n" \
                 "      or: obj.say(Muack::API.within(1..1))"
      e.was     .should.eq 'obj.say(2)'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'raise Expected if arguments do not match, show original args' do
      stub(Obj).say(is_a(Integer)){}
           Obj .say(2)
           Obj .say(0)
           Obj .say(1)
       spy(Obj).say(within(1..1))
       spy(Obj).say(within(0..0))
      e = should.raise(Muack::Unexpected){ Muack.verify }
      e.expected.should.eq "obj.say(Muack::API.within(1..1))\n" \
                 "      or: obj.say(Muack::API.within(0..0))"
      e.was     .should.eq 'obj.say(2)'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end
  end
end
