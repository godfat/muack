
require 'muack/mock'

module Muack
  class Proxy < Mock
    # used for mocked object to dispatch mocked method
    def __mock_block_call defi, actual_args
      object.__send__(defi.original_method, *actual_args)
    end
  end
end
