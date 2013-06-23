
require 'muack/mock'

module Muack
  class Stub < Mock
    # used for Muack::Session#verify
    def __mock_verify; true; end

    # used for mocked object to dispatch mocked method
    def __mock_dispatch msg, actual_args, actual_block
      defi = __mock_defis[msg].find{ |defi|
        __mock_check_args(defi.args, actual_args)
      }
      if defi
        __mock_block_call(defi.block, actual_args)
      else
        Mock.__send__(:raise, # basic object doesn't respond to raise
          Unexpected.new(object, __mock_defis[msg].first, actual_args))
      end
    end
  end
end
