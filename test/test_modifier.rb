
require 'muack/test'

describe Muack::Modifier do
  after do
    Muack.verify.should.eq true
    Muack::EnsureReset.call
  end

  describe 'times' do
    would 'mock multiple times' do
      3.times{ |i| mock(Obj).say(i){ i } }
      3.times{ |i| Obj.say(i).should.eq i }
    end

    would 'mock multiple times with times(n) modifier' do
      mock(Obj).say{ 0 }.times(3)
      3.times{ |i| Obj.say.should.eq 0 }
    end

    would 'mock 0 times with times(0) modifier' do
      mock(Obj).say{ 0 }.times(0).should.kind_of? Muack::Modifier
    end
  end

  describe 'returns' do
    would 'return with lexical scope' do
      mock(Obj).say.returns{0}
      Obj.say.should.eq 0
    end

    would 'return with dynamic scope' do
      mock(Obj).say.returns(:instance_exec => true){object_id}
      Obj.say.should.eq Obj.object_id
    end
  end

  describe 'peek_args' do
    would 'with lexical scope' do
      str = String.new('ff')
      stub(str).to_i.peek_args{16}
      str.to_i.should.eq 255
    end

    would 'with dynamic scope' do
      str = String.new('16')
      stub(str).to_i.peek_args(:instance_exec => true){Integer(self)}
      str.to_i.should.eq 22
    end

    would 'modify' do
      str = String.new('ff')
      stub(str).to_i(is_a(Integer)).peek_args{ |radix| radix * 2 }
      str.to_i(8).should.eq 255
    end

    would 'preserve args' do
      stub(Obj).say{|*a|a}.with_any_args.peek_args{|*a|a}
      Obj.say(0,1).should.eq [0,1]
    end

    would 'pass first args' do
      stub(Obj).say{|*a|a}.with_any_args.peek_args{|a|a}
      Obj.say(0,1).should.eq [0]
    end

    would 'pass nothing with nil' do
      stub(Obj).say{|*a|a}.with_any_args.peek_args{}
      Obj.say(0,1).should.eq []
    end

    would 'pass nothing with empty array' do
      stub(Obj).say{|*a|a}.with_any_args.peek_args{[]}
      Obj.say(0,1).should.eq []
    end

    would 'pass an empty array with [[]]' do
      stub(Obj).say{|*a|a}.with_any_args.peek_args{[[]]}
      Obj.say(0,1).should.eq [[]]
    end
  end

  describe 'peek_return' do
    would 'with lexical scope' do
      str = String.new('ff')
      stub(str).to_i.peek_return{16}
      str.to_i.should.eq 16
    end

    would 'with dynamic scope' do
      str = String.new('16')
      stub(str).to_i.peek_return(:instance_exec => true){Integer(self)+1}
      str.to_i.should.eq 17
    end

    would 'modify' do
      str = String.new('ff')
      stub(str).to_i(is_a(Integer)).peek_return{ |result| result * 2 }
      str.to_i(16).should.eq 510
    end
  end
end
