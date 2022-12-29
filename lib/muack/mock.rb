
require 'muack/definition'
require 'muack/modifier'
require 'muack/failure'
require 'muack/block'
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
    def method_missing msg, *args, &returns
      defi = Definition.new(msg, args, returns)
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
    def __mock_dispatch actual_call
      if defi = __mock_defis[actual_call.msg].shift
        __mock_disps_push(defi)
        if __mock_check_args(defi, actual_call)
          defi
        else
          Mock.__send__(:raise, # Wrong argument
            Unexpected.new(object, [defi], actual_call))
        end
      else
        __mock_failed(actual_call)
      end
    end

    # used for mocked object to dispatch mocked method
    def __mock_dispatch_call context, disp, actual_call, &proxy_super
      # resolving arguments
      call =
        if disp.peek_args
          args = __mock_block_call(context, disp.peek_args, actual_call)
          ActualCall.new(actual_call.msg, args, actual_call.block)
        else
          actual_call
        end

      # retrieve actual return
      ret =
        if disp.returns
          __mock_block_call(context, disp.returns, call)
        else
          __mock_proxy_call(context, disp, call, proxy_super)
        end

      # resolving return
      if disp.peek_return
        __mock_block_call(context, disp.peek_return, ret, true)
      else
        ret
      end
    end

    # used for Muack::Session#verify
    def __mock_verify
      __mock_defis.values.all?(&:empty?) || begin
        msg, defis_with_same_msg = __mock_defis.find{ |_, v| v.any? }
        args, defis = defis_with_same_msg.group_by(&:args).first
        dsize = __mock_disps[msg].count{ |d| d.args == args }
        Mock.__send__(:raise,   # Too little times
          Expected.new(object, defis.first, defis.size + dsize, dsize))
      end
    end

    # used for Muack::Session#reset
    def __mock_reset
      __mock_injected.each_value{ |defi| __mock_reset_method(defi) }
    end

    protected # get warnings for private attributes
    attr_accessor :__mock_defis, :__mock_disps, :__mock_injected

    private
    def __mock_inject_method defi
      __mock_injected[defi.msg] = defi
      target = Mock.prepare_target(object.singleton_class, defi.msg)
      defi.target = target
      Mock.store_original_method(target, defi)
      __mock_inject_mock_method(target, defi)
    end

    def __mock_reset_method defi
      defi.target.module_eval do
        remove_method(defi.msg)
        # restore original method
        if defi.original_method &&
           Mock.direct_method_defined?(self, defi.original_method)
          alias_method(defi.msg, defi.original_method)
          __send__(defi.visibility, defi.msg)
          remove_method(defi.original_method)
        end
      end
    end

    def self.direct_method_defined? mod, msg
      mod.method_defined?(msg, false) || # this doesn't cover private method
        mod.private_method_defined?(msg, false)
    end

    def self.method_visibility mod, msg, inherit=false
      if mod.public_method_defined?(msg, inherit)
        :public
      elsif mod.protected_method_defined?(msg, inherit)
        :protected
      elsif mod.private_method_defined?(msg, inherit)
        :private
      end
    end

    def self.prepare_target singleton_class, msg
      if singleton_class == singleton_class.ancestors.first # no prepended mod
        singleton_class
      else # check if we need to prepend an internal module to override
        index = singleton_class.ancestors.index(singleton_class)
        prepended_modules = singleton_class.ancestors[0...index]

        if prepended_modules.find{ |m| direct_method_defined?(m, msg) }
          # prepend an internal module to override the prepended module(s)
          name = :MuackPrepended
          if singleton_class.const_defined?(name)
            singleton_class.const_get(name)
          else
            prepended = ::Module.new
            singleton_class.const_set(name, prepended)
            singleton_class.private_constant(name)
            singleton_class.prepend(prepended)
            prepended
          end
        else # we don't need to override so singleton class is enough
          singleton_class
        end
      end
    end

    def self.store_original_method mod, defi
      if visibility = method_visibility(mod, defi.msg)
        # Defined in itself, we need to make alias
        original_method = find_new_name(mod, defi.msg)
        mod.__send__(:alias_method, original_method, defi.msg)
        defi.original_method = original_method
        defi.visibility = visibility
      elsif visibility = method_visibility(mod, defi.msg, true)
        # Defined in parent, we can just override
        defi.visibility = visibility
      else # Not defined, pick a reasonable default
        defi.visibility = :public
      end
    end

    def self.find_new_name mod, message, level=0
      if level >= (::ENV['MUACK_RECURSION_LEVEL'] || 9).to_i
        raise CannotFindInjectionName.new(level+1, message)
      end

      new_name = "__muack_#{name}_#{level}_#{message}".to_sym
      if direct_method_defined?(mod, new_name)
        find_new_name(mod, message, level+1)
      else
        new_name
      end
    end

    def __mock_inject_mock_method target, defi
      mock = self # remember the context
      target.__send__(:define_method, defi.msg){ |*actual_args, &actual_block|
        actual_call = ActualCall.new(defi.msg, actual_args, actual_block)
        disp = mock.__mock_dispatch(actual_call)
        mock.__mock_dispatch_call(self, disp, actual_call) do |call, has_kargs|
          # need the original context for calling `super`
          if has_kargs && kargs = call.args.last
            super(*call.args[0...-1], **kargs, &call.block)
          else
            super(*call.args, &call.block)
          end
        end
      }
      target.__send__(defi.visibility, defi.msg)
    end

    # used for __mock_dispatch
    def __mock_failed actual_call, disps=__mock_disps[actual_call.msg]
      if expected = __mock_find_checked_difi(disps, actual_call)
        Mock.__send__(:raise, # Too many times
          Expected.new(object, expected, disps.size, disps.size+1))
      else
        Mock.__send__(:raise, # Wrong argument
          Unexpected.new(object, disps, actual_call))
      end
    end

    # used for __mock_dispatch_call
    def __mock_block_call context, block, actual_call, peek_return=false
      # for AnyInstanceOf, we don't have the actual context at the time
      # we're defining it, so we update it here
      if block.kind_of?(Block)
        block.context = context
        instance_exec_block = block.block
      end

      if peek_return # actual_call is the actual return in this case
        block.call(actual_call, &instance_exec_block)
      else
        actual_block = actual_call.block || instance_exec_block
        if __mock_block_with_kargs?(instance_exec_block || block) &&
           kargs = actual_call.args.last
          block.call(*actual_call.args[0...-1], **kargs, &actual_block)
        else
          block.call(*actual_call.args, &actual_block)
        end
      end
    end

    # used for __mock_dispatch_call
    def __mock_proxy_call context, disp, call, proxy_super
      if disp.original_method # proxies for singleton methods with __send__
        if __mock_method_with_kargs?(context, disp.original_method) &&
          kargs = call.args.last
          context.__send__(
            disp.original_method, *call.args[0...-1], **kargs, &call.block)
        else
          context.__send__(disp.original_method, *call.args, &call.block)
        end
      else # proxies for instance methods with super
        proxy_super.call(call, __mock_super_with_kargs?(context, call.msg))
      end
    end

    def __mock_find_checked_difi defis, actual_call, meth=:find
      defis.public_send(meth){ |d| __mock_check_args(d, actual_call) }
    end

    def __mock_method_with_kargs? object, method_name
      __mock_block_with_kargs?(
        ::Kernel.instance_method(:method).bind(object).call(method_name))
    end

    def __mock_super_with_kargs? object, method_name
      super_method =
        ::Kernel.instance_method(:method).bind(object).call(method_name).
        super_method

      if super_method.owner.kind_of?(::Class) && super_method.name == :new
        initialize_method = ::Class.instance_method(:instance_method).
          bind(object).call(:initialize)
        __mock_block_with_kargs?(initialize_method)
      else
        __mock_block_with_kargs?(super_method)
      end
    end

    def __mock_block_with_kargs? block
      # there's no Symbol#start_with? in older Ruby
      block.parameters.dig(-1, 0).to_s.start_with?('key')
    end

    def __mock_check_args defi, actual_call
      return true if defi.args.size == 1 && defi.args.first == WithAnyArgs

      expected_args = defi.args
      actual_args = actual_call.args

      if expected_args.none?{ |arg| arg.kind_of?(Satisfying) }
        expected_args == actual_args

      elsif expected_args.size == actual_args.size
        expected_args.zip(actual_args).all?{ |(e, a)|
          if e.kind_of?(Satisfying) then e.match(a) else e == a end
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
