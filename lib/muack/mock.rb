
require 'muack/definition'
require 'muack/modifier'
require 'muack/failure'
require 'muack/error'

module Muack
  class Mock < BasicObject
    attr_reader :object
    def initialize object
      @object = object
      @__mock_injected = {}
      [:__mock_defis=, :__mock_disps=].each do |m|
        __send__(m, ::Hash.new{ |h, k| h[k] = [] })
      end
    end

    # Public API: Bacon needs this, or we often ended up with stack overflow
    def inspect
      "Muack::API.#{__mock_class.name[/\w+$/].downcase}(#{object.inspect})"
    end

    # Public API: Define mocked method
    def method_missing msg, *args, &block
      defi = Definition.new(msg, args, block)
      if injected = __mock_injected[defi.msg]
        defi.original_method = injected.original_method
      else
        __mock_inject_method(defi)
      end
      __mock_defis_push(defi)
      Modifier.new(self, defi)
    end

    # used for Muack::Modifier#times
    def __mock_defis_push defi
      __mock_defis[defi.msg] << defi
    end

    # used for Muack::Modifier#times
    def __mock_defis_pop defi
      __mock_defis[defi.msg].pop
    end

    # used for Muack::Modifier#times to determine if it's a mock or not
    def __mock_class
      (class << self; self; end).superclass
    end

    # used for mocked object to dispatch mocked method
    def __mock_dispatch msg, actual_args
      if defi = __mock_defis[msg].shift
        __mock_disps_push(defi)
        if __mock_check_args(defi.args, actual_args)
          defi
        else
          Mock.__send__(:raise, # Wrong argument
            Unexpected.new(object, [defi], msg, actual_args))
        end
      else
        defis = __mock_disps[msg]
        if expected = defis.find{ |d| __mock_check_args(d.args, actual_args) }
          Mock.__send__(:raise, # Too many times
            Expected.new(object, expected, defis.size, defis.size+1))
        else
          Mock.__send__(:raise, # Wrong argument
            Unexpected.new(object, defis, msg, actual_args))
        end
      end
    end

    # used for mocked object to dispatch mocked method
    def __mock_dispatch_call disp, actual_args, actual_block, &block
      args = __mock_peek_args(disp, actual_args)
      ret  = __mock_actuall_call(disp, args, actual_block, &block)
      __mock_peek_return(disp, ret)
    end

    # used for Muack::Session#verify
    def __mock_verify
      __mock_defis.values.all?(&:empty?) || begin
        msg, defis_with_same_msg = __mock_defis.find{ |_, v| v.size > 0 }
        args, defis = defis_with_same_msg.group_by(&:args).first
        dsize = __mock_disps[msg].select{ |d| d.args == args }.size
        Mock.__send__(:raise,   # Too little times
          Expected.new(object, defis.first, defis.size + dsize, dsize))
      end
    end

    # used for Muack::Session#reset
    def __mock_reset
      __mock_injected.each_value do |defi|
        object.singleton_class.module_eval do
          remove_method(defi.msg)
          # restore original method
          if instance_methods(false).include?(defi.original_method)
            alias_method(defi.msg, defi.original_method)
            remove_method(defi.original_method)
          end
        end
      end
    end

    protected # get warnings for private attributes
    attr_accessor :__mock_defis, :__mock_disps, :__mock_injected

    private
    def __mock_inject_method defi
      __mock_injected[defi.msg] = defi
      target = object.singleton_class # would be the class in AnyInstanceOf
      Mock.store_original_method(target, defi)
       __mock_inject_mock_method(target, defi)
    end

    def self.store_original_method klass, defi
      return unless klass.instance_methods(false).include?(defi.msg)
      # store original method
      original_method = find_new_name(klass, defi.msg)
      klass.__send__(:alias_method, original_method, defi.msg)
      defi.original_method = original_method
    end

    def self.find_new_name klass, message, level=0
      if level >= (::ENV['MUACK_RECURSION_LEVEL'] || 9).to_i
        raise CannotFindInjectionName.new(level+1, message)
      end

      new_name = "__muack_#{name}_#{level}_#{message}".to_sym
      if klass.instance_methods(false).include?(new_name)
        find_new_name(klass, message, level+1)
      else
        new_name
      end
    end

    def __mock_inject_mock_method target, defi
      mock = self # remember the context
      target.__send__(:define_method, defi.msg){ |*actual_args, &actual_block|
        disp = mock.__mock_dispatch(defi.msg, actual_args)
        mock.__mock_dispatch_call(disp, actual_args,
                                        actual_block){ |args, &block|
          if disp.original_method
            __send__(disp.original_method, *args, &block)
          else
            super(*args, &block)
          end
        }
      }
    end

    # used for __mock_dispatch_call
    def __mock_peek_args disp, args
      if disp.peek_args then disp.peek_args.call(*args) else args end
    end

    # used for __mock_dispatch_call
    def __mock_peek_return disp, ret
      if disp.peek_return then disp.peek_return.call(ret) else ret end
    end

    # used for __mock_dispatch_call
    def __mock_actuall_call disp, args, block
      if block = disp.block
        arity = block.arity
        if arity < 0
          block.call(*args             , &block)
        else
          block.call(*args.first(arity), &block)
        end
      else # proxy goes here
        # need the original context for proxy or AnyInstanceOf
        yield(*args) # ruby limitation: cannot pass block
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

    # used for Muack::Mock#__mock_dispatch
    def __mock_disps_push defi
      __mock_disps[defi.msg] << defi
    end
  end
end
