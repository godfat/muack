
require 'muack/test'

describe Muack::Proxy do
  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'proxy with regular method' do
      mock_proxy(Str).reverse
      Str.reverse.should.eq 'ooM'
    end

    should 'proxy multiple times' do
      2.times{ mock_proxy(Str).reverse }
      2.times{ Str.reverse.should.eq 'ooM' }
    end

    should 'proxy multiple times with super method' do
      2.times{ mock_proxy(Str).class }
      2.times{ Str.class.should.eq String }
    end

    should 'proxy and call the block' do
      mock_proxy(Obj).with(:inspect){ |str| str.reverse }
      Obj.inspect.should.eq 'jbo'
    end

    should 'proxy and call the block with super' do
      mock_proxy(Str).class{ |klass| klass.name.reverse  }
      Str.class.should.eq 'gnirtS'
    end

    should 'proxy and call, proxy and call' do
      mock_proxy(Obj).inspect
      Obj.inspect.should.eq 'obj'
      mock_proxy(Obj).inspect
      Obj.inspect.should.eq 'obj'
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.reset
      Muack::EnsureReset.call
    end

    should 'raise Muack::Expected error if passing unexpected argument' do
      mock_proxy(Str).reverse
      Str.reverse.should.eq 'ooM'
      begin
        Str.reverse
        'never'.should.eq 'reach'
      rescue Muack::Expected => e
        e.expected      .should.eq '"Moo".reverse()'
        e.expected_times.should.eq 1
        e.actual_times  .should.eq 2
        e.message       .should.eq "\nExpected: \"Moo\".reverse()\n  " \
                                   "called 1 times\n but was 2 times."
      end
    end
  end
end
