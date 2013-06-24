
require 'muack/mock'
require 'muack/stub'

module Muack
  module Proxy
    def __mock_block_call defi, actual_args, actual_block
      # handle block call in injected method, since we need to call origin
      defi # but we still want to know which defi gets dispatched!
    end

    def __mock_inject_mock_method target, defi
      mock = self # remember the context
      target.__send__(:define_method, defi.msg){|*actual_args, &actual_block|
        d = mock.__mock_dispatch(defi.msg, actual_args, actual_block)

        ret = if d.original_method
                __send__(d.original_method, *actual_args, &actual_block)
              else
                super(*actual_args, &actual_block)
              end

        if d.block
          d.block.call(ret)
        else
          ret
        end
      }
    end
  end

  class MockProxy < Mock
    include Proxy
  end

  class StubProxy < Stub
    include Proxy
  end
end
