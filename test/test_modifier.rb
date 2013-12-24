
require 'muack/test'

describe Muack::Modifier do
  after do
    Muack.verify.should.eq true
    Muack::EnsureReset.call
  end

  describe 'peek_args' do
    should 'plain value' do
      str = 'ff'
      stub(str).to_i.peek_args{16}
      str.to_i.should.eq 255
    end

    should 'modifying' do
      str = 'ff'
      stub(str).to_i(is_a(Integer)).peek_args{ |radix| radix * 2 }
      str.to_i(8).should.eq 255
    end
  end
end
