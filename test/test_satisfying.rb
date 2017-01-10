
require 'muack/test'

describe Muack::Satisfying do
  after do
    Muack.reset
    Muack::EnsureReset.call
  end

  describe Muack::Anything do
    would 'have human readable to_s and inspect' do
      matcher = anything
      expected = 'Muack::API.anything()'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    would 'satisfy' do
      mock(Str).say(anything){ |arg| arg*2 }
      Str.say(5).should.eq 10
      Muack.verify.should.eq true

      mock(Str).say(anything){ |arg| arg.upcase }
      Str.say('b').should.eq 'B'

      Muack.verify.should.eq true
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(anything){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(6, 7) }
      e.expected.should.eq 'obj.say(Muack::API.anything())'
      e.was     .should.eq 'obj.say(6, 7)'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end
  end

  describe Muack::IsA do
    would 'have human readable to_s and inspect' do
      matcher = is_a(String)
      expected = 'Muack::API.is_a(String)'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    would 'satisfy' do
      mock(Str).say(is_a(String)){ |arg| arg.reverse }
      Str.say('Foo').should.eq 'ooF'
      Muack.verify.should.eq true
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(is_a(Array)){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(false) }
      e.expected.should.eq 'obj.say(Muack::API.is_a(Array))'
      e.was     .should.eq 'obj.say(false)'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end
  end

  describe Muack::Matching do
    would 'have human readable to_s and inspect' do
      matcher = matching(/\w/)
      expected = 'Muack::API.matching(/\w/)'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    would 'satisfy' do
      mock(Str).say(matching(/\w/)){ |arg| arg }
      Str.say('aa').should.eq 'aa'
      Muack.verify.should.eq true
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(matching(/\w/)){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say('!') }
      e.expected.should.eq 'obj.say(Muack::API.matching(/\w/))'
      e.was     .should.eq 'obj.say("!")'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end
  end

  describe Muack::Including do
    would 'have human readable to_s and inspect' do
      matcher = including(2)
      expected = 'Muack::API.including(2)'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    would 'satisfy' do
      mock(Str).say(including(2)){ |arg| arg.first }
      Str.say([1, 2]).should.eq 1
      Muack.verify.should.eq true
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(including(2)){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say([1]) }
      e.expected.should.eq 'obj.say(Muack::API.including(2))'
      e.was     .should.eq 'obj.say([1])'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end
  end

  describe Muack::Within do
    would 'have human readable to_s and inspect' do
      matcher = within(0..9)
      expected = 'Muack::API.within(0..9)'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    would 'satisfy' do
      mock(Str).say(within(0..9)){ |arg| arg*2 }
      Str.say(5).should.eq 10
      Muack.verify.should.eq true

      mock(Str).say(within(%[a b])){ |arg| arg.upcase }
      Str.say('b').should.eq 'B'
      Muack.verify.should.eq true
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(within(0..5)){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(6) }
      e.expected.should.eq 'obj.say(Muack::API.within(0..5))'
      e.was     .should.eq 'obj.say(6)'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end
  end

  describe Muack::RespondingTo do
    would 'have human readable to_s and inspect' do
      matcher = responding_to(:id)
      expected = 'Muack::API.responding_to(:id)'
      matcher.to_s   .should.start_with? expected
      matcher.inspect.should.start_with? expected

      matcher = responding_to(:id, :reload)
      expected = 'Muack::API.responding_to(:id, :reload)'
      matcher.to_s   .should.start_with? expected
      matcher.inspect.should.start_with? expected
    end

    would 'satisfy' do
      mock(Str).say(responding_to(:verify, :reset)){ |arg| arg.name }
      Str.say(Muack).should.eq 'Muack'
      Muack.verify.should.eq true

      mock(Str).say(responding_to(:verify        )){ |arg| arg.name }
      Str.say(Muack).should.eq 'Muack'
      Muack.verify.should.eq true
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(responding_to(:nothing)){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(0) }
      e.expected.should.eq 'obj.say(Muack::API.responding_to(:nothing))'
      e.was     .should.eq 'obj.say(0)'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end
  end

  describe Muack::Where do
    would 'have human readable to_s and inspect' do
      matcher = where(:b => 2)
      expected = 'Muack::API.where({:b=>2})'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    would 'satisfy' do
      mock(Str).say(where(:b => 2)){ |arg| arg[:b] }
      Str.say(:b => 2).should.eq 2
      Muack.verify.should.eq true
    end

    would 'satisfy with satisfy' do
      mock(Str).say(where(:b => is_a(Integer))){ |arg| arg[:b] }
      Str.say(:b => 3).should.eq 3
      Muack.verify.should.eq true
    end

    would 'satisfy with satisfy recursive' do
      spec = where(:a => {:b => is_a(Integer)})
      mock(Str).say(spec){ |arg| arg[:a][:b] }
      Str.say(:a => {:b => 1}).should.eq 1
      Muack.verify.should.eq true
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(where(:b => 2)){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(:b => 1) }
      e.expected.should.eq 'obj.say(Muack::API.where({:b=>2}))'
      e.was     .should.eq 'obj.say({:b=>1})'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'raise Unexpected error if passing unsatisfied argument' do
      mock(Obj).say(where(:a => 0, :b => is_a(String))){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(:a => 0) }
      e.expected.should.eq \
        'obj.say(Muack::API.where({:a=>0, :b=>Muack::API.is_a(String)}))'
      e.was     .should.eq 'obj.say({:a=>0})'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'raise Unexpected error if passing unsatisfied argument' do
      mock(Obj).say(where(:a => 0, :b => is_a(Integer))){ 'boo' }
      e = should.raise(Muack::Unexpected){Obj.say(:a => 0, :b => 1, :c => 2)}
      e.expected.should.eq \
        'obj.say(Muack::API.where({:a=>0, :b=>Muack::API.is_a(Integer)}))'
      e.was     .should.eq 'obj.say({:a=>0, :b=>1, :c=>2})'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'recurse' do
      mock(Obj).say(where(:a =>
                      having(:b =>
                        allowing(:c => [is_a(Integer)])))){ 'boo' }
      e = should.raise(Muack::Unexpected){Obj.say(:a => 0)}
      e.expected.should.eq               \
        'obj.say(Muack::API.where({:a=>' \
          'Muack::API.having({:b=>'      \
            'Muack::API.allowing({:c=>'  \
              '[Muack::API.is_a(Integer)]})})}))'
      e.was     .should.eq 'obj.say({:a=>0})'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'respect all keys', :groups => [:only] do
      mock(Obj).say(where(:a => 0)){ 'nnf' }
      should.raise(Muack::Unexpected){Obj.say(:a => 0, :b => nil)}
    end
  end

  describe Muack::Having do
    would 'have human readable to_s and inspect' do
      matcher = having(:b => 2)
      expected = 'Muack::API.having({:b=>2})'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    would 'satisfy' do
      mock(Str).say(having(:b => 2)){ |arg| arg[:a] }
      Str.say(:a => 1, :b => 2).should.eq 1
      Muack.verify.should.eq true
    end

    would 'satisfy with satisfy' do
      mock(Str).say(having(:b => is_a(Integer))){ |arg| arg[:b] }
      Str.say(:a => 1, :b => 2).should.eq 2
      Muack.verify.should.eq true
    end

    would 'satisfy with satisfy recursive' do
      spec = having(:a => {:b => is_a(Integer)})
      mock(Str).say(spec){ |arg| arg[:a][:c] }
      Str.say(:a => {:b => 1, :c => 2}, :d => 3).should.eq 2
      Muack.verify.should.eq true
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(having(:b => 2)){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(:a => 1) }
      e.expected.should.eq 'obj.say(Muack::API.having({:b=>2}))'
      e.was     .should.eq 'obj.say({:a=>1})'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'raise Unexpected error if passing unsatisfied argument' do
      mock(Obj).say(having(:a => 0, :b => is_a(Integer))){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(:b => 1) }
      e.expected.should.eq \
        'obj.say(Muack::API.having({:a=>0, :b=>Muack::API.is_a(Integer)}))'
      e.was     .should.eq 'obj.say({:b=>1})'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'respect all keys' do
      mock(Obj).say(having(:a => 0, :b => nil)){ 'nnf' }
      should.raise(Muack::Unexpected){Obj.say(:a => 0)}
    end
  end

  describe Muack::Allowing do
    would 'have human readable to_s and inspect' do
      matcher = allowing(:b => 2)
      expected = 'Muack::API.allowing({:b=>2})'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    would 'satisfy' do
      mock(Str).say(allowing(:a => 0, :b => 1)){ |arg| arg[:a] }
      Str.say(:a => 0).should.eq 0
      Muack.verify.should.eq true
    end

    would 'satisfy with satisfy' do
      mock(Str).say(allowing(:a => is_a(Integer), :b => 1)){ |arg| arg[:a] }
      Str.say(:a => 0).should.eq 0
      Muack.verify.should.eq true
    end

    would 'satisfy with satisfy recursive' do
      spec = allowing(:a => {:b => is_a(Integer), :c => 1}, :d => 2)
      mock(Str).say(spec){ |arg| arg[:a][:b] }
      Str.say(:a => {:b => 0}).should.eq 0
      Muack.verify.should.eq true
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(allowing(:b => 2)){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(:a => 1) }
      e.expected.should.eq 'obj.say(Muack::API.allowing({:b=>2}))'
      e.was     .should.eq 'obj.say({:a=>1})'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'raise Unexpected error if passing unsatisfied argument' do
      mock(Obj).say(allowing(:b => is_a(String))){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(:b => '1', :c => 2) }
      e.expected.should.eq \
        'obj.say(Muack::API.allowing({:b=>Muack::API.is_a(String)}))'
      e.was     .should.eq 'obj.say({:b=>"1", :c=>2})'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end

    would 'respect all keys' do
      mock(Obj).say(allowing(:a => 0)){ 'nnf' }
      should.raise(Muack::Unexpected){Obj.say(:a => 0, :b => nil)}
    end
  end

  describe Muack::Satisfying do
    would 'have human readable to_s and inspect' do
      matcher = satisfying{ |arg| arg % 2 == 0 }
      expected = 'Muack::API.satisfying(#<Proc:'
      matcher.to_s   .should.start_with? expected
      matcher.inspect.should.start_with? expected
    end

    would 'not crash for top-level subclass' do
      Class.new(Muack::Satisfying){ def self.name; 'TopLevel'; end }.new.
        api_name.should.eq 'top_level'
    end

    would 'satisfy' do
      mock(Str).say(satisfying{ |arg| arg % 2 == 0 }){ |arg| arg + 1 }
      Str.say(14).should.eq 15
      Muack.verify.should.eq true
      Muack::EnsureReset.call
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(satisfying{ |arg| arg % 2 == 0 }){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(1) }
      e.expected.should.start_with? 'obj.say(Muack::API.satisfying(#<Proc:'
      e.was     .should.eq          'obj.say(1)'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end
  end

  describe Muack::Satisfying::Disj do
    would 'have human readable to_s and inspect' do
      matcher = is_a(TrueClass) | is_a(FalseClass)
      expected = 'Muack::API.is_a(TrueClass) | Muack::API.is_a(FalseClass)'
      matcher.to_s   .should.start_with? expected
      matcher.inspect.should.start_with? expected
    end

    would 'satisfy' do
      mock(Str).say(is_a(TrueClass) | is_a(FalseClass)){ |arg| !arg }
      Str.say(false).should.eq true
      Muack.verify  .should.eq true
      Muack::EnsureReset.call
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(within('0'..'1') | matching(/a/)){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say('2') }
      e.expected.should.eq \
        'obj.say(Muack::API.within("0".."1") | Muack::API.matching(/a/))'
      e.was     .should.eq \
        'obj.say("2")'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end
  end

  describe Muack::Satisfying::Conj do
    would 'have human readable to_s and inspect' do
      matcher = responding_to(:ancestors) & is_a(Class)
      expected =
        'Muack::API.responding_to(:ancestors) & Muack::API.is_a(Class)'
      matcher.to_s   .should.eq expected
      matcher.inspect.should.eq expected
    end

    would 'satisfy' do
      mock(Str).say(responding_to(:ancestors) & is_a(Class)){ |arg| arg.new }
      Str.say(String).should.eq ''
      Muack.verify   .should.eq true
      Muack::EnsureReset.call
    end

    would 'raise Unexpected error if passing unexpected argument' do
      mock(Obj).say(anything & within(0..1)){ 'boo' }
      e = should.raise(Muack::Unexpected){ Obj.say(2) }
      e.expected.should.eq \
        'obj.say(Muack::API.anything() & Muack::API.within(0..1))'
      e.was     .should.eq \
        'obj.say(2)'
      e.message .should.eq "\nExpected: #{e.expected}\n but was: #{e.was}"
    end
  end
end
