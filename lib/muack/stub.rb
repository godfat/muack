
require 'muack/mock'

module Muack
  class Stub < Mock
    # used for Muack::Session#verify
    def __mock_verify; true; end

    # used for mocked object to dispatch mocked method
    def __mock_dispatch msg, actual_args, actual_block
      defi = __mock_defis[msg].find{ |d|
        __mock_check_args(d.args, actual_args)
      }
      if defi
        __mock_block_call(defi, actual_args)
      else
        Mock.__send__(:raise, # Wrong argument
          Unexpected.new(object, __mock_defis[msg], msg, actual_args))
      end
    end
  end
end
