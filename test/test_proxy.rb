
require 'muack/test'

describe Muack::Mock do
  describe 'Muack.verify==true' do
    after do
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    should 'proxy with regular method' do
      mock(Str).reverse
      Str.reverse.should.eq 'ooM'
    end

    should 'proxy with private method' do
      mock(Obj).private.peek_return(&:reverse)
      Obj.__send__(:private).should.eq 'irp'
    end

    should 'proxy multiple times' do
      2.times{ mock(Str).reverse }
      2.times{ Str.reverse.should.eq 'ooM' }
    end

    should 'proxy multiple times with super method' do
      2.times{ mock(Str).class }
      2.times{ Str.class.should.eq String }
    end

    should 'proxy with super method for multiple arguments' do
      args = %w[o u]
      mock(Str).tr(*args)
      Str.tr(*args).should.eq 'Muu'
    end

    should 'return modifier itself for any modifier methods' do
      mock(Str).to_s.peek_return{ |s| s.reverse }.times(2).
        with_any_args.with_any_args
      2.times{ Str.to_s.should.eq 'ooM' }
    end

    should 'proxy and call the original method' do
      mock(Obj).method_missing(:inspect).peek_return{ |str| str.reverse }
      Obj.inspect.should.eq 'jbo'
    end

    should 'proxy and call the original method for multiple arguments' do
      args = %w[o u]
      mock(Obj).aloha(*args)
      mock(Obj).aloha
      Obj.aloha(*args).should.eq args
      Obj.aloha.should.eq [0, 1]
    end

    should 'proxy and call the block with super' do
      mock(Str).class.peek_return{ |k| k.name.reverse }
      Str.class.should.eq 'gnirtS'
    end

    should 'mock proxy and call, mock proxy and call' do
      mock(Obj).class.peek_return{ |k| k.name.reverse }
      Obj.class.should.eq 'tcejbO'
      mock(Obj).class.peek_return{ |k| k.name.upcase }
      Obj.class.should.eq 'OBJECT'
    end

    should 'stub proxy and call, stub proxy and call' do
      stub(Obj).kind_of?(Object).peek_return{ |b| !b }
      Obj.kind_of?(Object).should.eq false
      stub(Obj).kind_of?(String).peek_return{ |b| b.to_s }
      Obj.kind_of?(String).should.eq 'false'
    end

    should 'stub proxy with any times' do
      stub(Obj).class.peek_return{ |k| k.name.downcase }
      3.times{ Obj.class.should.eq 'object' }
    end

    should 'stub proxy and spy' do
      stub(Obj).class.peek_return{ |k| k.name.downcase }
      Obj.class.should.eq 'object'
      spy(Obj).class
    end
  end

  describe 'Muack.verify==false' do
    after do
      Muack.reset
      Muack::EnsureReset.call
    end

    should 'raise Expected error if passing unexpected argument' do
      mock(Str).reverse
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
