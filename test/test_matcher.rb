
require 'muack/test'

describe Muack::Matcher do
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
  end

  describe Muack::Within do
    should 'have human readable to_s and inspect' do
      matcher = within(0..9)
      expected = 'Muack::API.within(0..9)'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end
  end
end
