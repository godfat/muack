
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
      mock_proxy(Str).class{ |k| k.name.reverse  }
      Str.class.should.eq 'gnirtS'
    end

    should 'mock_proxy and call, mock_proxy and call' do
      mock_proxy(Obj).class{ |k| k.name.reverse }
      Obj.class.should.eq 'tcejbO'
      mock_proxy(Obj).class{ |k| k.name.upcase }
      Obj.class.should.eq 'OBJECT'
    end

    should 'stub_proxy and call, stub_proxy and call' do
      stub_proxy(Obj).kind_of?(Object){ |b| !b }
      Obj.kind_of?(Object).should.eq false
      stub_proxy(Obj).kind_of?(String){ |b| b.to_s }
      Obj.kind_of?(String).should.eq 'false'
    end

    should 'stub_proxy with any times' do
      stub_proxy(Obj).class{ |k| k.name.downcase }
      3.times{ Obj.class.should.eq 'object' }
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
