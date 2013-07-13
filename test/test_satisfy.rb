
require 'muack/test'

describe Muack::Satisfy do
  describe Muack::IsA do
    should 'have human readable to_s and inspect' do
      matcher = is_a(String)
      expected = 'Muack::API.is_a(String)'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    should 'satisfy' do
      mock(Str).say(is_a(String)){ |arg| arg.reverse }
      Str.say('Foo').should.eq 'ooF'
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'raise Unexpected error if passing unexpected argument' do
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

  describe Muack::Anything do
    should 'have human readable to_s and inspect' do
      matcher = anything
      expected = 'Muack::API.anything()'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    should 'satisfy' do
      mock(Str).say(anything){ |arg| arg*2 }
      Str.say(5).should.eq 10
      Muack.verify.should.eq true

      mock(Str).say(anything){ |arg| arg.upcase }
      Str.say('b').should.eq 'B'

      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(anything){ 'boo' }
      begin
        Obj.say(6, 7)
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq 'obj.say(Muack::API.anything())'
        e.was     .should.eq 'obj.say(6, 7)'
        e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
      ensure
        Muack.reset
        Muack::EnsureReset.call
      end
    end
  end

  describe Muack::Match do
    should 'have human readable to_s and inspect' do
      matcher = match(/\w/)
      expected = 'Muack::API.match(/\w/)'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    should 'satisfy' do
      mock(Str).say(match(/\w/)){ |arg| arg }
      Str.say('aa').should.eq 'aa'
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(match(/\w/)){ 'boo' }
      begin
        Obj.say('!')
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq 'obj.say(Muack::API.match(/\w/))'
        e.was     .should.eq 'obj.say("!")'
        e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
      ensure
        Muack.reset
        Muack::EnsureReset.call
      end
    end
  end

  describe Muack::HashIncluding do
    should 'have human readable to_s and inspect' do
      matcher = hash_including(:b => 2)
      expected = 'Muack::API.hash_including({:b=>2})'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    should 'satisfy' do
      mock(Str).say(hash_including(:b => 2)){ |arg| arg[:a] }
      Str.say(:a => 1, :b => 2).should.eq 1
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(hash_including(:b => 2)){ 'boo' }
      begin
        Obj.say(:a => 1)
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq 'obj.say(Muack::API.hash_including({:b=>2}))'
        e.was     .should.eq 'obj.say({:a=>1})'
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

    should 'satisfy' do
      mock(Str).say(within(0..9)){ |arg| arg*2 }
      Str.say(5).should.eq 10
      Muack.verify.should.eq true

      mock(Str).say(within(%[a b])){ |arg| arg.upcase }
      Str.say('b').should.eq 'B'

      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'raise Unexpected error if passing unexpected argument' do
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

  describe Muack::RespondTo do
    should 'have human readable to_s and inspect' do
      matcher = respond_to(:id)
      expected = 'Muack::API.respond_to(:id)'
      matcher.to_s   .should.start_with expected
      matcher.inspect.should.start_with expected

      matcher = respond_to(:id, :reload)
      expected = 'Muack::API.respond_to(:id, :reload)'
      matcher.to_s   .should.start_with expected
      matcher.inspect.should.start_with expected
    end

    should 'satisfy' do
      mock(Str).say(respond_to(:verify)){ |arg| arg.name }
      Str.say(Muack).should.eq 'Muack'
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(respond_to(:nothing)){ 'boo' }
      begin
        Obj.say(0)
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq 'obj.say(Muack::API.respond_to(:nothing))'
        e.was     .should.eq 'obj.say(0)'
        e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
      ensure
        Muack.reset
        Muack::EnsureReset.call
      end
    end
  end

  describe Muack::Satisfy do
    should 'have human readable to_s and inspect' do
      matcher = satisfy{ |arg| arg % 2 == 0 }
      expected = 'Muack::API.satisfy(#<Proc:'
      matcher.to_s   .should.start_with expected
      matcher.inspect.should.start_with expected
    end

    should 'satisfy' do
      mock(Str).say(satisfy{ |arg| arg % 2 == 0 }){ |arg| arg + 1 }
      Str.say(14).should.eq 15
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(satisfy{ |arg| arg % 2 == 0 }){ 'boo' }
      begin
        Obj.say(1)
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.start_with 'obj.say(Muack::API.satisfy(#<Proc:'
        e.was     .should.eq         'obj.say(1)'
        e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
      ensure
        Muack.reset
        Muack::EnsureReset.call
      end
    end
  end
end
