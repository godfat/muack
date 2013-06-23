
require 'muack/mock'

module Muack
  class Stub < Mock
    def __mock_verify; true; end
    # used for mocked object to dispatch mocked method
    def __mock_dispatch msg, actual_args, actual_block
    end
  end
end
