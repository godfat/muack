
require 'muack/test'

describe Muack::Matcher do
  should 'have human readable to_s and inspect' do
    matcher = is_a(String)
    expected = 'Muack.match(:kind_of?, String)'
    matcher.to_s   .should.eq expected
    matcher.inspect.should.eq expected
  end
end
