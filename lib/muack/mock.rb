
module Muack
  class Mock < BasicObject
    Definition = ::Class.new(::Struct.new(:message, :args, :block, :caller))

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
      if __check_args(defi.args, args)
        ::Muack.session.dispatches << defi if @verify
        return unless defi.block
        arity = defi.block.arity
        if arity < 0
          defi.block.call(*args)
        else
          defi.block.call(*args.first(arity))
        end
      else
        ::Muack.__send__(:raise, Unexpected.new(__mock_object, defi, args))
      end
    end

    def __check_args target, source
      if target.none?{ |arg| arg.kind_of?(Matcher) }
        target == source
      elsif target.size == source.size
        target.zip(source).all?{ |(t, s)|
          if t.kind_of?(Matcher)
            t.match(s)
          else
            t == s
          end
        }
      else
        false
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
