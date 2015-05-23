
require 'muack/session'
require 'muack/satisfying'

module Muack
  def self.verify obj=nil
    session.verify(obj)
  ensure
    reset(obj)
  end

  def self.session
    Thread.current[:muack_session] ||= Muack::Session.new
  end

  def self.reset obj=nil
    session = Thread.current[:muack_session]
    session && session.reset(obj)
    Thread.current[:muack_session] = nil unless obj
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

    def coat obj=Object.new
      ret = Muack.session.coat(obj)
      if block_given? then yield(ret) else ret end
    end

    def spy obj
      ret = Muack.session.spy(obj)
      if block_given? then yield(ret) else ret end
    end

    def any_instance_of klass
      ret = Muack.session.any_instance_of(klass)
      if block_given? then yield(ret) else ret end
    end

    def anything
      Muack::Anything.new
    end

    def is_a klass
      Muack::IsA.new(klass)
    end

    def matching regexp
      Muack::Matching.new(regexp)
    end

    def including element
      Muack::Including.new(element)
    end

    def within range_or_array
      Muack::Within.new(range_or_array)
    end

    def responding_to *msg
      Muack::RespondingTo.new(*msg)
    end

    def where spec
      Muack::Where.new(spec)
    end

    def having spec
      Muack::Having.new(spec)
    end

    def allowing spec
      Muack::Allowing.new(spec)
    end

    def satisfying &block
      Muack::Satisfying.new(&block)
    end

    def match regexp
      $stderr.puts("Muack::API.match is deprecated." \
                   " Use Muack::API.matching instead.")
      matching(regexp)
    end

    def respond_to *msg
      $stderr.puts("Muack::API.respond_to is deprecated." \
                   " Use Muack::API.responding_to instead.")
      responding_to(*msg)
    end

    def hash_including spec
      $stderr.puts("Muack::API.hash_including is deprecated." \
                   " Use Muack::API.having instead.")
      having(spec)
    end

    def satisfy &block
      $stderr.puts("Muack::API.satisfy is deprecated." \
                   " Use Muack::API.satisfying instead.")
      satisfying(&block)
    end
  end
end
