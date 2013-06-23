
require 'muack/mock'
require 'muack/stub'

require 'muack/satisfy'
require 'muack/session'

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
    def mock object=Object.new
      Muack.session[object.object_id] ||= Muack::Mock.new(object)
    end

    def stub object=Object.new
      Muack.session[object.object_id] ||= Muack::Stub.new(object)
    end

    # TODO: test
    def proxy object=Object.new
    end

    # TODO: test
    def any_instance_of
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
