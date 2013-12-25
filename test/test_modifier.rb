
require 'muack/test'

describe Muack::Modifier do
  after do
    Muack.verify.should.eq true
    Muack::EnsureReset.call
  end

  describe 'times' do
    should 'mock multiple times' do
      3.times{ |i| mock(Obj).say(i){ i } }
      3.times{ |i| Obj.say(i).should.eq i }
    end

    should 'mock multiple times with times(n) modifier' do
      mock(Obj).say{ 0 }.times(3)
      3.times{ |i| Obj.say.should.eq 0 }
    end

    should 'mock 0 times with times(0) modifier' do
      mock(Obj).say{ 0 }.times(0).should.kind_of Muack::Modifier
    end
  end

  describe 'returns' do
    should 'return with lexical scope' do
      mock(Obj).say.returns{0}
      Obj.say.should.eq 0
    end

    should 'return with dynamic scope' do
      mock(Obj).say.returns(:instance_exec => true){object_id}
      Obj.say.should.eq Obj.object_id
    end
  end

  describe 'peek_args' do
    should 'with lexical scope' do
      str = 'ff'
      stub(str).to_i.peek_args{16}
      str.to_i.should.eq 255
    end

    should 'with dynamic scope' do
      str = '16'
      stub(str).to_i.peek_args(:instance_exec => true){Integer(self)}
      str.to_i.should.eq 22
    end

    should 'modify' do
      str = 'ff'
      stub(str).to_i(is_a(Integer)).peek_args{ |radix| radix * 2 }
      str.to_i(8).should.eq 255
    end
  end
end
