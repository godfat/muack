
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

    should 'mock existing method' do
      mock(Obj).to_s{ 'zoo' }
      Obj.to_s.should.eq 'zoo'
    end

    should 'mock twice' do
      mock(Obj).say(true){ Obj.saya }
      mock(Obj).saya{ 'coo' }
      Obj.say(true).should.eq 'coo'
    end

    should 'also mock with with' do
      mock(Str).with(:say, 0){ 0 }
      Str.say(0).should.eq 0
      Muack.verify.should.eq true
      mock(Str).with(:say, 1){ 1 }
      lambda{ Str.say(2) }.should.raise(Muack::Unexpected)
      Muack.reset
    end

    should 'mock multiple times' do
      3.times{ |i| mock(Obj).say(i){ i } }
      3.times{ |i| Obj.say(i).should.eq i }
    end

    should 'mock multiple times with times(n) modifier' do
      mock(Obj).say{ 0 }.times(3)
      3.times{ |i| Obj.say.should.eq 0 }
    end

    should 'mix mock and stub' do
      mock(Obj).say { 0 }
      stub(Obj).saya{ 1 }
      3.times{ Obj.saya.should.eq 1 }
               Obj.say .should.eq 0
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.reset
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
        e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
      end
    end

    should 'raise Muack::Expected error if mock methods were not called' do
      mock(Obj).say(true){ 'boo' }
      begin
        Muack.verify
      rescue Muack::Expected => e
        e.expected      .should.eq 'obj.say(true)'
        e.expected_times.should.eq 1
        e.actual_times  .should.eq 0
        e.message       .should.eq "\nExpected: obj.say(true)\n  " \
                                   "called 1 times\n but was 0 times."
      end
    end
  end
end
