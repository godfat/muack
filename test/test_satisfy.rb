
require 'muack/test'

describe Muack::Satisfy do
  describe Muack::IsA do
    should 'have human readable to_s and inspect' do
      matcher = is_a(String)
      expected = 'Muack::API.is_a(String)'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    should 'match' do
      mock(Str).say(is_a(String)){ |arg| arg.reverse }
      Str.say('Foo').should.eq 'ooF'
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'raise Muack::Unexpected error if passing unexpected argument' do
      mock(Obj).say(is_a(Array)){ 'boo' }
      begin
        Obj.say(false)
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq 'obj.say(Muack::API.is_a(Array))'
        e.was     .should.eq 'obj.say(false)'
        e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
      ensure
        Muack.reset
        Muack::EnsureReset.call
      end
    end
  end

  describe Muack::Within do
    should 'have human readable to_s and inspect' do
      matcher = within(0..9)
      expected = 'Muack::API.within(0..9)'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    should 'match' do
      mock(Str).say(within(0..9)){ |arg| arg*2 }
      Str.say(5).should.eq 10
      Muack.verify.should.eq true

      mock(Str).say(within(%[a b])){ |arg| arg.upcase }
      Str.say('b').should.eq 'B'

      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'raise Muack::Unexpected error if passing unexpected argument' do
      mock(Obj).say(within(0..5)){ 'boo' }
      begin
        Obj.say(6)
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq 'obj.say(Muack::API.within(0..5))'
        e.was     .should.eq 'obj.say(6)'
        e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
      ensure
        Muack.reset
        Muack::EnsureReset.call
      end
    end
  end
end
