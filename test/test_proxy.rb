
require 'muack/test'

describe Muack::Mock do
  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'proxy with regular method' do
      mock(Str).reverse.proxy
      Str.reverse.should.eq 'ooM'
    end

    should 'proxy multiple times' do
      2.times{ mock(Str).reverse.proxy }
      2.times{ Str.reverse.should.eq 'ooM' }
    end

    should 'proxy multiple times with super method' do
      2.times{ mock(Str).class.proxy }
      2.times{ Str.class.should.eq String }
    end

    should 'proxy and call the block' do
      mock(Obj).method_missing(:inspect){ |str| str.reverse }.proxy
      Obj.inspect.should.eq 'jbo'
    end

    should 'proxy and call the block with super' do
      mock(Str).class{ |k| k.name.reverse }.proxy
      Str.class.should.eq 'gnirtS'
    end

    should 'mock proxy and call, mock proxy and call' do
      mock(Obj).class{ |k| k.name.reverse }.proxy
      Obj.class.should.eq 'tcejbO'
      mock(Obj).class{ |k| k.name.upcase }.proxy
      Obj.class.should.eq 'OBJECT'
    end

    should 'stub proxy and call, stub proxy and call' do
      stub(Obj).kind_of?(Object){ |b| !b }.proxy
      Obj.kind_of?(Object).should.eq false
      stub(Obj).kind_of?(String){ |b| b.to_s }.proxy
      Obj.kind_of?(String).should.eq 'false'
    end

    should 'stub proxy with any times' do
      stub(Obj).class{ |k| k.name.downcase }.proxy
      3.times{ Obj.class.should.eq 'object' }
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.reset
      Muack::EnsureReset.call
    end

    should 'raise Muack::Expected error if passing unexpected argument' do
      mock(Str).reverse.proxy
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
