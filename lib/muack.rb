
require 'muack/session'
require 'muack/satisfy'

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

    def is_a klass
      Muack::IsA.new(klass)
    end

    def anything
      Muack::Anything.new
    end

    def match regexp
      Muack::Match.new(regexp)
    end

    def match_spec spec
      Muack::MatchSpec.new(spec)
    end

    def superset_of spec
      Muack::SupersetOf.new(spec)
    end

    def subset_of spec
      Muack::SubsetOf.new(spec)
    end

    def including element
      Muack::Including.new(element)
    end

    def within range_or_array
      Muack::Within.new(range_or_array)
    end

    def respond_to *msg
      Muack::RespondTo.new(*msg)
    end

    def satisfy &block
      Muack::Satisfy.new(&block)
    end

    def hash_including spec
      $stderr.puts("Muack::API.hash_including is deprecated." \
                   " Use Muack::API.superset_of instead.")
      superset_of(spec)
    end
  end
end
