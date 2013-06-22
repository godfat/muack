
require 'muack/test'

describe Muack::Mock do
  obj = Object.new
  str = 'Moo'
  def obj.inspect
    'obj'
  end

  ensure_reset = lambda{
    [obj, str].each do |o|
      o.methods.select{ |m|
        m.to_s.start_with?('__muack_mock') || m.to_s.start_with?('say')
      }.should.empty
    end
  }

  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      ensure_reset.call
    end

    should 'mock with regular method' do
      mock(obj).say(true){ 'boo' }
      obj.say(true).should.eq 'boo'
    end

    should 'mock with is_a matcher' do
      mock(str).say(is_a(String)){ |arg| arg.reverse }
      str.say('Foo').should.eq 'ooF'
    end

    should 'stub with regular method' do
      stub(obj).say{ 'goo' }
      3.times{ obj.say.should.eq 'goo' }
    end

    should 'mock twice' do
      mock(obj).say(true){ obj.saya }
      mock(obj).saya{ 'coo' }
      obj.say(true).should.eq 'coo'
    end

    should 'mock external object' do
      mock(str).say{ str.sub('M', 'H') }
      str.say.should.eq 'Hoo'
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.verify.should.eq false
      ensure_reset.call
    end

    should 'raise Muack::Unexpected error if passing unexpected argument' do
      mock(obj).say(true){ 'boo' }
      begin
        obj.say(false)
        'never'.should.eq 'reach'
      rescue Muack::Unexpected => e
        e.expected.should.eq 'obj.say(true)'
        e.was     .should.eq 'obj.say(false)'
      end
    end
  end
end
