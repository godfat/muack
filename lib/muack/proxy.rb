
require 'muack/mock'

module Muack
  class Proxy < Mock
    # used for mocked object to dispatch mocked method
    def __mock_block_call defi, actual_args
      if defi.original_method && !object.kind_of?(AnyInstanceOf)
        result = object.__send__(defi.original_method, *actual_args)
        if defi.block
          defi.block.call(result)
        else
          result
        end
      end
    end

    def __mock_inject_method defi
      mock = self # remember the context

      object.singleton_class.module_eval do
        if instance_methods(false).include?(defi.msg)
          # store original method
          original_method = Mock.find_new_name(self, defi.msg)
          alias_method original_method, defi.msg
          defi.original_method = original_method
        end

        # define mocked method
        define_method defi.msg do |*actual_args, &actual_block|
          r = mock.__mock_dispatch(defi.msg, actual_args, actual_block)
          if defi.original_method
            if mock.object.kind_of?(AnyInstanceOf)
              result = __send__(defi.original_method, *actual_args, &actual_block)
              if defi.block
                defi.block.call(result)
              else
                result
              end
            else
              r
            end
          else
            result = super(*actual_args, &actual_block)
            if defi.block
              defi.block.call(result)
            else
              result
            end
          end
        end
      end
    end
  end
end
