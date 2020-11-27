
require 'muack/mock'

module Muack
  class Coat < Mock
    # used for mocked object to dispatch mocked method
    def __mock_dispatch actual_call
      defi = super
      if __mock_defis[defi.msg].empty?
        __mock_reset_method(defi)
        __mock_injected.delete(defi.msg)
      end
      defi
    end
  end
end
