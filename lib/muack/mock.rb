
require 'muack/definition'
require 'muack/modifier'
require 'muack/failure'

module Muack
  class Mock < BasicObject
    attr_reader :object
    def initialize object
      @object = object
    end

    # Public API: Define mocked method
    def with msg, *args, &block
      defi = Definition.new(msg, args, block)
      __mock_inject_method(defi) if __mock_defi_push(defi).size == 1
      Modifier.new(self, defi)
    end

    # Public API: Define mocked method, the convenient way
    alias_method :method_missing, :with

    # used for Muack::Modifier#times
    def __mock_defi_push defi
      (__mock_defis[defi.msg] ||= []) << defi
    end

    # used for mocked object to dispatch mocked method
    def __mock_dispatch msg, actual_args, actual_block
      defi = __mock_defis[msg].shift
      if defi
        __mock_disp_push(defi)
        if __mock_check_args(defi.args, actual_args)
          __mock_block_call(defi, actual_args)
        else
          Mock.__send__(:raise, # basic object doesn't respond to raise
            Unexpected.new(object, [defi], msg, actual_args))
        end
      else
        defis = __mock_disps[msg]
        Mock.__send__(:raise,
          Expected.new(object, defis, defis.size, defis.size+1))
      end
    end

    # used for Muack::Session#verify
    def __mock_verify
      __mock_defis.values.all?(&:empty?) || begin
        # TODO: this would be tricky to show the desired error message :(
        #       do we care about orders? shall we inject methods one by one?
        msg, defis = __mock_defis.find{ |k, v| v.size > 0 }
        disps      = (__mock_disps[msg] || []).size
        Mock.__send__(:raise,
          Expected.new(object, defis, defis.size + disps, disps))
      end
    end

    # used for Muack::Session#reset
    def __mock_reset
      [__mock_defis, __mock_disps].
      flat_map{ |h| h.values.flatten }.compact.each do |defi|
        object.singleton_class.module_eval do
          methods = instance_methods(false)
          if methods.include?(defi.msg) # removed mocked method
            remove_method(defi.msg)     # could be removed by other defi
          end
          if methods.include?(defi.original_method) # restore original method
            alias_method defi.msg, defi.original_method
            remove_method defi.original_method
          end
        end
      end
    end

    private
    def __mock_inject_method defi
      mock = self # remember the context

      object.singleton_class.module_eval do
        if instance_methods(false).include?(defi.msg)
          # store original method
          original_method = Mock.find_new_name(self, defi.msg).to_sym
          alias_method original_method, defi.msg
          defi.original_method = original_method
        end

        # define mocked method
        define_method defi.msg do |*actual_args, &actual_block|
          mock.__mock_dispatch(defi.msg, actual_args, actual_block)
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

    def __mock_block_call defi, actual_args
      if block = defi.block
        arity = block.arity
        if arity < 0
          block.call(*actual_args)
        else
          block.call(*actual_args.first(arity))
        end
      end
    end

    def __mock_check_args expected_args, actual_args
      if expected_args == [WithAnyArgs]
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

    def __mock_disp_push defi
      (__mock_disps[defi.msg] ||= []) << defi
    end

    def __mock_defis
      @__mock_defis ||= {}
    end

    def __mock_disps
      @__mock_disps ||= {}
    end
  end
end
