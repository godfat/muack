
require 'muack/mock'
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
    @session = nil
  end

  module API
    module_function
    def mock object=Object.new
      Muack::Mock.new(object)
    end

    def stub object=Object.new
      Muack::Mock.new(object, false)
    end

    def is_a klass
      match(:kind_of?, klass)
    end

    def match message, *args
      Muack::Matcher.new(message, args)
    end
  end
end
