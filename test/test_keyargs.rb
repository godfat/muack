
require 'muack/test'

describe Muack::Mock do
  after do
    Muack.verify.should.eq true
    Muack::EnsureReset.call
  end

  describe 'passing single hash' do
    would 'hash literal' do
      mock(Obj).say({}, &:itself)

      expect(Obj.say({})).eq({})
    end

    would 'hash literal with satisfying check' do
      mock(Obj).say(is_a(Hash), &:itself)

      expect(Obj.say({})).eq({})
    end

    would 'hash value' do
      arg = {}

      mock(Obj).say(arg, &:itself)

      expect(Obj.say(arg)).eq(arg)
    end

    would 'non-empty hash' do
      mock(Obj).say(a: 0, &:itself)

      expect(Obj.say(a: 0)).eq(a: 0)
    end

    would 'non-empty hash with satisfying check' do
      mock(Obj).say(where(a: 0), &:itself)

      expect(Obj.say(a: 0)).eq(a: 0)
    end
  end

  describe 'keyargs mock' do
    would 'local block' do
      mock(Obj).say.with_any_args.returns{ |a:| a }

      expect(Obj.say(a: 0)).eq(0)
    end

    would 'instance method' do
      mock(Obj).bonjour(a: 0, b: 1)

      expect(Obj.bonjour(a: 0, b: 1)).eq([0, 1])
    end

    would 'singleton method' do
      mock(Obj).single_bonjour(a: 0, b: 1)

      expect(Obj.single_bonjour(a: 0, b: 1)).eq([0, 1])
    end

    would 'prepended method' do
      mock(Obj).prepend_bonjour(a: 0, b: 1)

      expect(Obj.prepend_bonjour(a: 0, b: 1)).eq([0, 1])
    end

    would 'peek_args' do
      mock(Obj).say.with_any_args.
        peek_args{ |a:| [{a: a.succ}] }.
        returns{ |a:| a.succ }

      expect(Obj.say(a: 0)).eq(2)
    end

    would 'peek_args with instance_exec' do
      mock(Obj).say.with_any_args.
        peek_args(instance_exec: true){ |a:| [{a: object_id}] }.
        returns{ |a:| a }

      expect(Obj.say(a: 0)).eq(Obj.object_id)
    end
  end
end
