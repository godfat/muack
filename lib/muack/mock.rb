
require 'muack/definition'
require 'muack/modifier'
require 'muack/failure'
require 'muack/block'
require 'muack/error'

module Muack
  EmptyBlock = proc{}

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
    def __mock_dispatch_call context, disp, actual_args, actual_block, &_yield
      args = if disp.peek_args
               __mock_block_call(context, disp.peek_args,
                                 actual_args, actual_block, true)
             else
               actual_args
             end

      ret = if disp.returns
              __mock_block_call(context, disp.returns,
                                args, actual_block, true)
            elsif disp.original_method # proxies for singleton methods
              context.__send__(disp.original_method, *args, &actual_block)
            else # proxies for instance methods
              # need the original context for calling `super`
              # ruby: can't pass a block to yield, so we name it _yield
              _yield.call(*args, &actual_block)
            end

      if disp.peek_return
        __mock_block_call(context, disp.peek_return, ret, EmptyBlock, false)
      else
        ret
      end
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
          if instance_methods(false).include?(defi.original_method) ||
             private_instance_methods(false).include?(defi.original_method)
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
      privilege = Mock.store_original_method(target, defi)
      __mock_inject_mock_method(target, defi, privilege)
    end

    def self.store_original_method klass, defi
      privilege = if klass.instance_methods(false).include?(defi.msg)
        :public # TODO: forget about protected methods?
      elsif klass.private_instance_methods(false).include?(defi.msg)
        :private
      end

      return :public unless privilege
      # store original method
      original_method = find_new_name(klass, defi.msg)
      klass.__send__(:alias_method, original_method, defi.msg)
      defi.original_method = original_method
      privilege
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

    def __mock_inject_mock_method target, defi, privilege=:public
      mock = self # remember the context
      target.__send__(:define_method, defi.msg){ |*actual_args, &actual_block|
        disp = mock.__mock_dispatch(defi.msg, actual_args)
        mock.__mock_dispatch_call(self, disp, actual_args,
                                              actual_block) do |args, &block|
          super(*args, &block)
        end
      }
      target.__send__(privilege, defi.msg)
    end

    # used for __mock_dispatch_call
    def __mock_block_call context, block, actual_args, actual_block, splat
      return unless block
      # for AnyInstanceOf, we don't have actually context at the time
      # we're defining it, so we update it here
      block.context = context if block.kind_of?(Block)
      if splat
        block.call(*actual_args, &actual_block)
      else # peek_return doesn't need splat
        block.call(actual_args, &actual_block)
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
