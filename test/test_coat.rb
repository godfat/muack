
require 'muack/test'

describe Muack::Coat do
  after do
    Muack.verify.should.eq true
    Muack::EnsureReset.call
  end

  would 'wear out' do
    coat(Str).to_s{ 'Coat' }
    Str.to_s.should.eq 'Coat'
    Str.to_s.should.eq 'Moo'
  end

  would 'wear out 2 times' do
    coat(Str).to_s{ 'Coat' }.times(2)
    2.times{ Str.to_s.should.eq 'Coat' }
    Str.to_s.should.eq 'Moo'
  end

  would 'call the original method' do
    coat(Str).to_s{ Str.to_s.reverse }
    Str.to_s.should.eq 'ooM'
    Str.to_s.should.eq 'Moo'
  end

  would 'raise Expected error if coated method is not called' do
    coat(Obj).say{ 'nnf' }
    e = should.raise(Muack::Expected){ Muack.verify }
    e.expected      .should.eq 'obj.say()'
    e.expected_times.should.eq 1
    e.actual_times  .should.eq 0
    e.message       .should.eq "\nExpected: obj.say()\n  " \
                               "called 1 times\n but was 0 times."
  end

  would 'raise Expected error if coated method is not called' do
    coat(Obj).say{ 'nnf' }.times(2)
    Obj.say.should.eq 'nnf'
    e = should.raise(Muack::Expected){ Muack.verify }
    e.expected      .should.eq 'obj.say()'
    e.expected_times.should.eq 2
    e.actual_times  .should.eq 1
    e.message       .should.eq "\nExpected: obj.say()\n  " \
                               "called 2 times\n but was 1 times."
  end
end
