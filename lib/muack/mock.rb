
module Muack
  class Mock < BasicObject
    Definition = ::Class.new(::Struct.new(:message, :args, :block,
                                          :original_method))

    attr_reader :__mock_object
    def initialize object
      @__mock_object = object
    end

    # Public API: Define mocked method
    def method_missing msg, *args, &block
      definition = Definition.new(msg, args, block)
      __mock_definitions(definition)
      __mock_inject_method(definition)
      self
    end

    # Public API
    def times number
    end

    # Public API
    def with_any_args
    end

    # used for mocked object to dispatch mocked method
    def __mock_dispatch defi, actual_args, actual_block
      if __mock_check_args(defi.args, actual_args)
        __mock_dispatches(defi)
        if defi.block
          arity = defi.block.arity
          if arity < 0
            defi.block.call(*actual_args)
          else
            defi.block.call(*actual_args.first(arity))
          end
        end
      else
        Mock.__send__(:raise, # basic object doesn't respond to raise
          Unexpected.new(__mock_object, defi, actual_args))
      end
    end

    # used for Muack::Session#verify
    def __mock_verify
      __mock_definitions == __mock_dispatches || begin
        # TODO: this would be tricky to show the desired error message :(
        #       do we care about orders? shall we inject methods one by one?
        defi = (__mock_definitions - __mock_dispatches).first
        Mock.__send__(:raise,
          Expected.new(__mock_object, defi, __mock_definitions.size,
                                            __mock_dispatches.size))
      end
    end

    # used for Muack::Session#reset
    def __mock_reset
      __mock_definitions.each do |defi|
        __mock_object.singleton_class.module_eval do
          remove_method(defi.message) # removed mocked method
          alias_method defi.message, defi.original_method if
            defi.original_method      # restore original method
        end
      end
    end

    private
    def __mock_inject_method defi
      mock, obj = self, __mock_object # remember the context

      obj.singleton_class.module_eval do
        if obj.respond_to?(defi.message) # store original method
          original_method = Mock.find_new_name(obj, defi.message)
          alias_method original_method, defi.message
          defi.original_method = original_method
        end

        # define mocked method
        define_method defi.message do |*actual_args, &actual_block|
          mock.__mock_dispatch(defi, actual_args, actual_block)
        end
      end
    end

    def self.find_new_name object, message, level=0
      raise "Cannot find a suitable method name, tried #{level+1} times." if
        level >= 9

      new_name = "__muack_mock_#{level}_#{message}"
      if object.respond_to?(message)
        find_new_name(object, message, level+1)
      else
        new_name
      end
    end

    def __mock_check_args expected_args, actual_args
      if expected_args.none?{ |arg| arg.kind_of?(Satisfy) }
        expected_args == actual_args

      elsif expected_args.size == actual_args.size
        expected_args.zip(actual_args).all?{ |(e, a)|
          if e.kind_of?(Satisfy) then e.match(a) else e == a end
        }
      else
        false
      end
    end

    def __mock_definitions defi=nil
      @__mock_definitions ||= []
      if defi then @__mock_definitions << defi else @__mock_definitions end
    end

    def __mock_dispatches defi=nil
      @__mock_dispatches ||= []
      if defi then @__mock_dispatches  << defi else @__mock_dispatches  end
    end
  end
end
