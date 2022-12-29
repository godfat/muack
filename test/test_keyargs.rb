
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
    copy :tests do
      would 'local block' do
        mock(obj).say.with_any_args.returns{ |a:| a }

        expect(instance.say(a: 0)).eq(0)
      end

      would 'instance method' do
        # https://github.com/jruby/jruby/issues/7545
        skip if RUBY_ENGINE == 'jruby' && obj.kind_of?(Muack::AnyInstanceOf)

        mock(obj).bonjour(a: 0, b: 1)

        expect(instance.bonjour(a: 0, b: 1)).eq([0, 1])
      end

      would 'prepended method' do
        mock(obj).prepend_bonjour(a: 0, b: 1)

        expect(instance.prepend_bonjour(a: 0, b: 1)).eq([0, 1])
      end
    end

    describe 'with direct mock' do
      def obj
        Obj
      end

      def instance
        obj
      end

      paste :tests

      would 'singleton method' do
        mock(obj).single_bonjour(a: 0, b: 1)

        expect(instance.single_bonjour(a: 0, b: 1)).eq([0, 1])
      end
    end

    describe 'with any_instance_of' do
      def obj
        any_instance_of(Cls)
      end

      def instance
        @instance ||= Cls.new
      end

      paste :tests
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

  describe 'proxy new' do
    would 'handle initialize via ordinal new' do
      kargs_initialize = Class.new do
        def initialize a:
          @a = a
        end
        attr_reader :a
      end

      mock(kargs_initialize).new(a: 0)

      expect(kargs_initialize.new(a: 0).a).eq(0)
    end

    would 'handle overridden new without keyword arguments' do
      kargs_initialize = Class.new do
        def initialize a:
          @a = a
        end
        attr_reader :a

        def self.new a
          super(a: a)
        end
      end

      mock(kargs_initialize).new(0)

      expect(kargs_initialize.new(0).a).eq(0)
    end

    would 'handle overridden new with keyword arguments' do
      kargs_initialize = Class.new do
        def initialize a
          @a = a
        end
        attr_reader :a

        def self.new a:
          super(a)
        end
      end

      mock(kargs_initialize).new(a: 0)

      expect(kargs_initialize.new(a: 0).a).eq(0)
    end
  end
end
