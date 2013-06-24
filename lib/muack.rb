
require 'muack/mock'
require 'muack/stub'
require 'muack/proxy'

require 'muack/satisfy'
require 'muack/session'

require 'muack/any_instance_of'

module Muack
  def self.verify
    session.verify
  ensure
    reset
  end

  def self.session
    @session ||= Muack::Session.new
  end

  def self.reset
    @session && @session.reset
    @session = nil
  end

  module API
    module_function
    def mock obj=Object.new
      ret = Muack.session["mk #{obj.__id__}"] ||= Muack::Mock.new(obj)
      if block_given? then yield(ret) else ret end
    end

    def stub obj=Object.new
      ret = Muack.session["sb #{obj.__id__}"] ||= Muack::Stub.new(obj)
      if block_given? then yield(ret) else ret end
    end

    def mock_proxy obj=Object.new
      ret = Muack.session["mp #{obj.__id__}"] ||= Muack::MockProxy.new(obj)
      if block_given? then yield(ret) else ret end
    end

    def stub_proxy obj=Object.new
      ret = Muack.session["sp #{obj.__id__}"] ||= Muack::StubProxy.new(obj)
      if block_given? then yield(ret) else ret end
    end

    def any_instance_of klass
      yield Muack::AnyInstanceOf.new(klass)
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
