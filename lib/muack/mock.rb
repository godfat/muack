
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
      @__mock_definitions == @__mock_dispatches
    end

    # used for Muack::Session#reset
    def __mock_reset
      __mock_methods.each do |defi|
        __mock_object.singleton_class.module_eval do
          remove_method(defi.message) # removed mocked method
          alias_method defi.message, defi.original_method if
            defi.original_method   # restore original method
        end
      end
    end

    private
    def __mock_inject_method defi
      mock = self # remember the context

      __mock_object.singleton_class.module_eval do
        if method_defined?(defi.message) # store original method
          original_method = Mock.find_alias_name(defi.message)
          alias_method original_method, defi.message
          defi.original_method = original_method
        end

        # define mocked method
        define_method defi.message do |*actual_args, &actual_block|
          mock.__mock_dispatch(defi, actual_args, actual_block)
        end
      end
    end

    def self.find_alias_name message, level=0
      raise "Cannot find a suitable method name, tried #{level+1} times." if
        level >= 10

      new_name = "__muack_mock_#{level}_#{message}"
      if method_defined?(new_name)
        __mock_find_alias_name(message, level+1)
      else
        new_name
      end
    end

    def __mock_check_args expected_args, actual_args
      if expected_args.none?{ |arg| arg.kind_of?(Matcher) }
        expected_args == actual_args

      elsif expected_args.size == actual_args.size
        expected_args.zip(actual_args).all?{ |(e, a)|
          if e.kind_of?(Matcher) then e.match(a) else e == a end
        }
      else
        false
      end
    end

    def __mock_definitions defi; (@__mock_definitions ||= []) << defi; end
    def __mock_dispatches  defi; (@__mock_dispatches  ||= []) << defi; end
  end
end
