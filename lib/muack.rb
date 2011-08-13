
require 'singleton'

module Muack
  module_function
  def mock object=Object.new
    Mock.new(object)
  end

  def verify
    session.verify
  ensure
    reset
  end

  def session
    @session ||= Session.new
  end

  def reset
    @session = nil
  end

  class Session
    attr_reader :mocks, :definitions, :dispatches
    def initialize
      @mocks, @definitions, @dispatches = [], [], []
    end

    def verify
      definitions == dispatches
    end
  end

  class Definition < Struct.new(:message, :args, :block, :caller)
  end

  class Unexpected < RuntimeError
    def initialize defi, args
      super(
        "\nExpected: #{defi.message}(#{defi.args.join(', ')})\n" \
          " but was: #{defi.message}(#{args.join(', ')})"
      )
    end
  end
end

module Muack
  class Mock < BasicObject
    attr_reader :__mock_object
    def initialize object
      @__mock_object = object
      @end = false
      ::Muack.session.mocks << self
    end

    def __mock_methods
      @__mock_methods ||= []
    end

    def method_missing msg, *args, &block
      if end?
        # TODO: what to with block?
        if defi = lookup(msg, args)
          dispatch(defi, msg, args, block)
        else
          delegate(msg, args, block)
        end
      else
        __mock_methods << Definition.new(msg, args, block)
        ::Muack.session.definitions << __mock_methods.last
        self
      end
    end

    def delegate msg, args, block
      __mock_object.public_send(msg, *args, &block)
    end

    def lookup msg, args
      __mock_methods.find{ |defi| defi.message == msg }
    end

    def dispatch defi, msg, args, block
      if defi.args == args
        ::Muack.session.dispatches << defi
        defi.block.call(self)
      else
        ::Muack.send(:raise, Unexpected.new(defi, args))
      end
    end

    def end
      @end = true
      self
    end

    def end?
      !!@end
    end
  end
end

m = Muack.mock.foo(2){ |s| s.bar }.bar{ 2 }.end

puts m.foo(2)
p Muack.verify

m = Muack.mock("Hello World!").sleep{ |s| s.sub('o', '') }.end

p m.sleep
p Muack.verify
