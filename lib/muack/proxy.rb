
require 'muack/mock'

module Muack
  class Proxy < Mock
    def __mock_block_call defi, actual_args
      # handle block call in injected method, since we need to call origin
    end

    def __mock_inject_mock_method target, defi
      mock = self # remember the context
      target.__send__(:define_method, defi.msg){|*actual_args, &actual_block|
        mock.__mock_dispatch(defi.msg, actual_args, actual_block)

        ret = if defi.original_method
                __send__(defi.original_method, *actual_args, &actual_block)
              else
                super(*actual_args, &actual_block)
              end

        if defi.block
          defi.block.call(ret)
        else
          ret
        end
      }
    end
  end
end
