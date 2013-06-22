
require 'muack/test'

describe Muack::Mock do
  obj = Object.new
  moo = 'Moo'
  def obj.inspect
    'obj'
  end

  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      [obj, moo].each do |o|
        o.methods.select{ |m| m.to_s.start_with?('__muack_mock') }.
          should.empty
      end
    end

    should 'mock with regular method' do
      mock(obj).moo(true){ 'boo' }
      obj.moo(true).should.eq 'boo'
    end

    should 'mock with is_a matcher' do
      mock(moo).say(is_a(String)){ |arg| arg.reverse }
      moo.say('Foo').should.eq 'ooF'
    end

    should 'stub with regular method' do
      stub(obj).foo{ 'goo' }
      3.times{ obj.foo.should.eq 'goo' }
    end

    should 'mock twice' do
      mock(obj).moo(true){ obj.boo }
      mock(obj).boo{ 'coo' }
      obj.moo(true).should.eq 'coo'
    end

    should 'mock external object' do
      mock(moo).sleep{ moo.sub('M', 'H') }
      moo.sleep.should.eq 'Hoo'
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.verify.should.eq false
    end

    should 'raise Muack::Unexpected error if passing unexpected argument' do
      mock(obj).moo(true){ 'boo' }
      begin
        obj.moo(false)
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq 'obj.moo(true)'
        e.was     .should.eq 'obj.moo(false)'
      end
    end
  end
end
