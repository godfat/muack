
module Muack
  class Mock < BasicObject
    Definition  = ::Class.new(::Struct.new(:message, :args, :block,
                                           :original_method))
    WithAnyArgs = ::Object.new

    attr_reader :object
    def initialize object
      @object = object
    end

    # Public API: Define mocked method
    def with msg, *args, &block
      definition = Definition.new(msg, args, block)
      __mock_definitions(definition)
      __mock_inject_method(definition)
      self
    end

    # Public API
    def with_any_args
      __mock_definitions.last.args = WithAnyArgs
      self
    end

    # Public API
    # TODO: test
    def times number
      __mock_definitions.concat([__mock_definitions.last] * number)
      self
    end

    # Public API: Define mocked method, the convenient way
    alias_method :method_missing, :with

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
          Unexpected.new(object, defi, actual_args))
      end
    end

    # used for Muack::Session#verify
    def __mock_verify
      __mock_definitions.sort_by(&:object_id) == __mock_dispatches.sort_by(&:object_id) || begin
        # TODO: this would be tricky to show the desired error message :(
        #       do we care about orders? shall we inject methods one by one?
        defi = (__mock_definitions - __mock_dispatches).first
        Mock.__send__(:raise,
          Expected.new(object, defi, __mock_definitions.size,
                                            __mock_dispatches.size))
      end
    end

    # used for Muack::Session#reset
    def __mock_reset
      __mock_definitions.each do |defi|
        object.singleton_class.module_eval do
          methods = instance_methods(false)
          if methods.include?(defi.message)         # removed mocked method
            remove_method(defi.message) # could be removed by other defi
          end
          if methods.include?(defi.original_method) # restore original method
            alias_method defi.message, defi.original_method
            remove_method defi.original_method
          end
        end
      end
    end

    private
    def __mock_inject_method defi
      mock = self # remember the context

      object.singleton_class.module_eval do
        if instance_methods(false).include?(defi.message)
          # store original method
          original_method = Mock.find_new_name(self, defi.message)
          alias_method original_method, defi.message
          defi.original_method = original_method
        end

        # define mocked method
        define_method defi.message do |*actual_args, &actual_block|
          mock.__mock_dispatch(defi, actual_args, actual_block)
        end
      end
    end

    def self.find_new_name klass, message, level=0
      raise "Cannot find a suitable method name, tried #{level+1} times." if
        level >= 9

      new_name = "__muack_mock_#{level}_#{message}"
      if klass.instance_methods(false).include?(new_name)
        find_new_name(object, message, level+1)
      else
        new_name
      end
    end

    def __mock_check_args expected_args, actual_args
      if expected_args == WithAnyArgs
        true
      elsif expected_args.none?{ |arg| arg.kind_of?(Satisfy) }
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
