
require 'muack/test'

describe Muack::AnyInstanceOf do
  klass = Class.new{ def f; 0; end; private; def g; 1; end }

  would 'mock any_instance_of' do
    any_instance_of(klass){ |inst| mock(inst).say{ true } }
    obj = klass.new
    obj.say              .should.eq true
    obj.respond_to?(:say).should.eq true
    Muack.verify         .should.eq true
    obj.respond_to?(:say).should.eq false
  end

  would 'mock any_instance_of with instance_exec' do
    any_instance_of(klass){ |inst|
      mock(inst).say.returns(:instance_exec => true){ f } }
    obj = klass.new
    obj.say              .should.eq obj.f
    Muack.verify         .should.eq true
    obj.respond_to?(:say).should.eq false
  end

  would 'proxy any_instance_of' do
    any_instance_of(klass){ |inst| mock(inst).f }
    obj = klass.new
    obj.f       .should.eq 0
    Muack.verify.should.eq true
    obj.f       .should.eq 0
  end

  would 'proxy any_instance_of for private methods' do
    any_instance_of(klass){ |inst| mock(inst).g.peek_return{|i|i+1} }
    obj = klass.new
    obj.__send__(:g).should.eq 2
    Muack.verify    .should.eq true
    obj.__send__(:g).should.eq 1
  end

  would 'proxy any_instance_of with peek_return' do
    any_instance_of(klass){ |inst| mock(inst).f.peek_return{|i|i+1} }
    obj = klass.new
    obj.f       .should.eq 1
    Muack.verify.should.eq true
    obj.f       .should.eq 0
  end

  would 'proxy with multiple any_instance_of call' do
    any_instance_of(klass){ |inst| mock(inst).f.peek_return{ |i| i+1 } }
    any_instance_of(klass){ |inst| mock(inst).f.peek_return{ |i| i+2 } }
    obj = klass.new
    obj.f.should.eq 1
    obj.f.should.eq 2
    Muack.verify.should.eq true
    obj.f.should.eq 0
  end

  would 'mock with multiple any_instance_of call' do
    any_instance_of(klass){ |inst| mock(inst).f(is_a(Integer)){ |i| i+1 } }
    any_instance_of(klass){ |inst| mock(inst).f(is_a(Integer)){ |i| i+2 } }
    obj = klass.new
    obj.f(2).should.eq 3
    obj.f(2).should.eq 4
    Muack.verify.should.eq true
    obj.f.should.eq 0
  end

  would 'share the same counts for different instances' do
    times = 2
    any_instance_of(klass){ |inst| mock(inst).f{0}.times(times) }
    times.times{ klass.new.f.should.eq 0 }
    Muack.verify.should.eq true
  end

  would 'stub proxy with any_instance_of and spy' do
    any_instance_of(klass){ |inst| stub(inst).f.peek_return{ |i| i+3 } }
    obj = klass.new
    obj.f.should.eq 3
    obj.f.should.eq 3
    spy(any_instance_of(klass)).f.times(2)
    Muack.verify.should.eq true
    obj.f.should.eq 0
  end

  would 'stub with any_instance_of and spy under satisfied' do
    any_instance_of(klass){ |inst| stub(inst).f{ 5 } }
    obj = klass.new
    obj.f.should.eq 5
    spy(any_instance_of(klass)).f.times(2)

    e = should.raise(Muack::Expected){ Muack.verify }
    expected = /Muack::API\.any_instance_of\(.+?\)\.f\(\)/
    e.expected      .should =~ expected
    e.expected_times.should.eq 2
    e.actual_times  .should.eq 1

    obj.f.should.eq 0
  end

  would 'stub with any_instance_of and spy over satisfied' do
    any_instance_of(klass){ |inst| stub(inst).f{ 2 } }
    obj = klass.new
    2.times{ obj.f.should.eq 2 }
    spy(any_instance_of(klass)).f

    e = should.raise(Muack::Expected){ Muack.verify }
    expected = /Muack::API\.any_instance_of\(.+?\)\.f\(\)/
    e.expected      .should =~ expected
    e.expected_times.should.eq 1
    e.actual_times  .should.eq 2

    obj.f.should.eq 0
  end

  describe 'mock any_instance_of on a method defined higher up' do
    methods_count = klass.instance_methods.size

    would 'not store a backup method' do
      any_instance_of(klass){ |inst| mock(inst).to_s{ 'to_s' } }

      expect(klass.new.to_s).eq 'to_s'
      expect(klass.instance_methods.size).eq methods_count
    end
  end

  # Brought from rspec-mocks and it's currently failing on rspec-mocks
  would 'stub any_instance_of on module extending it self' do
    mod = Module.new {
      extend self
      def hello; :hello; end
    }

    any_instance_of(mod){ |inst| stub(inst).hello{ :stub } }

    expect(mod.hello).eq(:stub)
    expect(Muack.verify)
    expect(mod.hello).eq(:hello)
  end
end
