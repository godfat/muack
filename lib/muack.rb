
module Muack
  module_function
  def mock object=Object.new
    Mock.new(object)
  end

  def stub object=Object.new
    Mock.new(object, false)
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
    def initialize object, verfiy=true
      @__mock_object = object
      @verify = verfiy
      @end = false
      ::Muack.session.mocks << self
    end

    def __mock_methods
      @__mock_methods ||= []
    end

    def method_missing msg, *args, &block
      if __mock_end?
        # TODO: what to with block?
        if defi = __mock_lookup(msg, args)
          __mock_dispatch(defi, msg, args, block)
        else
          __mock_delegate(msg, args, block)
        end
      else
        __mock_methods << Definition.new(msg, args, block)
        ::Muack.session.definitions << __mock_methods.last if @verify
        @end = true
        self
      end
    end

    def __mock_delegate msg, args, block
      __mock_object.public_send(msg, *args, &block)
    end

    def __mock_lookup msg, args
      __mock_methods.find{ |defi| defi.message == msg }
    end

    def __mock_dispatch defi, msg, args, block
      if defi.args == args
        ::Muack.session.dispatches << defi if @verify
        if defi.block
          if defi.block.arity.abs == 1
            defi.block.call(self)
          else
            defi.block.call
          end
        end
      else
        ::Muack.send(:raise, Unexpected.new(defi, args))
      end
    end

    def mock
      @end = false
      self
    end

    def __mock_end?
      @end
    end
  end
end

m = Muack.mock.foo(2){ |s| s.bar }.mock.bar{ 2 }

puts m.foo(2)
p Muack.verify

m = Muack.mock("Hello World!").sleep{ |s| s.sub('o', '') }

p m.sleep
p Muack.verify

q = Muack.stub.quack{}
q.quack
q.quack
p Muack.verify
