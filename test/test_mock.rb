
require 'muack/test'

describe Muack::Mock do
  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'inspect' do
      mock(Obj).inspect.should.eq "Muack::API.mock(obj)"
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
      mock(Str).method_missing(:say, 0){ 0 }
      Str.say(0).should.eq 0
      Muack.verify.should.eq true
      mock(Str).method_missing(:say, 1){ 1 }
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

    should 'mock 0 times with times(0) modifier' do
      mock(Obj).say{ 0 }.times(0).should.kind_of Muack::Modifier
    end

    should 'mix mock and stub' do
      mock(Obj).say { 0 }
      stub(Obj).saya{ 1 }
      3.times{ Obj.saya.should.eq 1 }
               Obj.say .should.eq 0
    end

    should 'unnamed mock' do
      mock.say{1}.object.say.should.eq 1
    end

    should 'mock and call, mock and call' do
      mock(Obj).say{0}
      Obj.say.should.eq 0
      mock(Obj).say{1}
      Obj.say.should.eq 1
    end

    should 'not remove original singleton method' do
      obj = Class.new{ def self.f; 0; end }
      2.times{ mock(obj).f{ 1 }  }
      2.times{ obj.f.should.eq 1 }
      Muack.verify.should.eq true
      obj.f       .should.eq 0
    end

    should 'return values with returns with a value' do
      mock(Obj).say.returns(0)
      Obj.say.should.eq 0
    end

    should 'return values with returns with a block' do
      mock(Obj).say.returns{0}
      Obj.say.should.eq 0
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.reset
      Muack::EnsureReset.call
    end

    should 'raise Unexpected error if passing unexpected argument' do
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

    should 'have correct message for multiple mocks with the same name' do
      2.times{ mock(Obj).say }
      begin
        3.times{ Obj.say }
        'never'.should.eq 'reach'
      rescue Muack::Expected => e
        e.expected.should.eq 'obj.say()'
        e.expected_times.should.eq 2
        e.actual_times  .should.eq 3
        e.message       .should.eq "\nExpected: obj.say()\n  " \
                                   "called 2 times\n but was 3 times."
      end
    end

    should 'have correct message for mocks with special satisfier' do
      mock(Obj).say(anything)
      begin
        Obj.say(1)
        Obj.say(2)
        'never'.should.eq 'reach'
      rescue Muack::Expected => e
        expected = 'obj.say(Muack::API.anything())'
        e.expected.should.eq expected
        e.expected_times.should.eq 1
        e.actual_times  .should.eq 2
        e.message       .should.eq "\nExpected: #{expected}\n  " \
                                   "called 1 times\n but was 2 times."
      end
    end

    should 'raise if a mock with times(0) gets called' do
      mock(Obj).say.times(0)
      begin
        Obj.say
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq nil
        e.was     .should.eq 'obj.say()'
        e.message .should.start_with "\nExpected: #{e.was}\n"
      end
    end

    should 'raise if a mock with times(0) gets called with diff sig' do
      mock(Obj).say.times(0)
      begin
        Obj.say(true)
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq nil
        e.was     .should.eq 'obj.say(true)'
        e.message .should.start_with "\nExpected: #{e.was}\n"
      end
    end

    should 'raise Unexpected when calling with diff sig' do
      mock(Obj).say(true){1}
      Obj.say(true).should.eq 1
      begin
        Obj.say
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq 'obj.say(true)'
        e.was     .should.eq 'obj.say()'
        e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
      end
    end

    should 'raise Expected error if mock methods not called' do
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

    should 'show first not enough calls' do
      mock(Obj).say{ 'boo' }.times(2)
      mock(Obj).saya        .times(2)
      begin
        Obj.say
        Muack.verify
      rescue Muack::Expected => e
        e.expected      .should.eq 'obj.say()'
        e.expected_times.should.eq 2
        e.actual_times  .should.eq 1
        e.message       .should.eq "\nExpected: obj.say()\n  " \
                                   "called 2 times\n but was 1 times."
      end
    end
  end
end
