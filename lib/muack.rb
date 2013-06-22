
require 'muack/mock'
require 'muack/stub'
require 'muack/matcher'
require 'muack/session'
require 'muack/failure'

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

    def is_a klass
      Muack::IsA.new(klass)
    end

    def within range_or_array_or_hash
      Muack::Within.new(range_or_array_or_hash)
    end

    def matcher &block
      Muack::Matcher.new(block)
    end
  end
end
