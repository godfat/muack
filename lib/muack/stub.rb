
require 'muack/mock'

module Muack
  class Stub < Mock
    def __mock_verify; true; end
    # used for mocked object to dispatch mocked method
    def __mock_dispatch msg, actual_args, actual_block
      defi = __mock_definitions[msg].shift
      if defi
        __mock_definitions[msg] << defi
        __mock_dispatches(defi)
        if __mock_check_args(defi.args, actual_args)
          if defi.block
            arity = defi.block.arity
            if arity < 0
              defi.block.call(*actual_args)
            else
              defi.block.call(*actual_args.first(arity))
            end
          end
        else
          Mock.__send__(:raise, # basic object doesn't respond to raise
            Unexpected.new(object, defi, actual_args))
        end
      else
        defis = __mock_dispatches[msg]
        Mock.__send__(:raise,
          Expected.new(object, defis.first, defis.size, defis.size+1))
      end
    end
  end
end
