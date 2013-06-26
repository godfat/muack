
require 'muack/session'
require 'muack/satisfy'

module Muack
  def self.verify
    session.verify
  ensure
    reset
  end

  def self.session
    Thread.current[:muack_session] ||= Muack::Session.new
  end

  def self.reset
    session = Thread.current[:muack_session]
    session && session.reset
    Thread.current[:muack_session] = nil
  end

  module API
    module_function
    def mock obj=Object.new
      ret = Muack.session.mock(obj)
      if block_given? then yield(ret) else ret end
    end

    def stub obj=Object.new
      ret = Muack.session.stub(obj)
      if block_given? then yield(ret) else ret end
    end

    def any_instance_of klass
      ret = Muack.session.any_instance_of(klass)
      if block_given? then yield(ret) else ret end
    end

    def is_a klass
      Muack::IsA.new(klass)
    end

    def anything
      Muack::Anything.new
    end

    def match regexp
      Muack::Match.new(regexp)
    end

    def hash_including hash
      Muack::HashIncluding.new(hash)
    end

    def within range_or_array
      Muack::Within.new(range_or_array)
    end

    def satisfy &block
      Muack::Satisfy.new(block)
    end
  end
end
