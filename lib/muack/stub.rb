
require 'muack/mock'

module Muack
  class Stub < Mock
    # used for Muack::Session#verify
    def __mock_verify; true; end

    # used for Muack::Modifier#times
    def __mock_defis_push defi
      # since stubs never wear out, the reverse ordering would make more sense
      # so that the latter wins over the previous one (overwrite)
      __mock_defis[defi.msg].unshift(defi)
    end

    # used for mocked object to dispatch mocked method
    def __mock_dispatch actual_call
      defis = __mock_defis[actual_call.msg]

      if disp = __mock_find_checked_difi(defis, actual_call)
        # our spies are interested in this
        __mock_disps_push(actual_call)
        disp
      else
        Mock.__send__(:raise, # Wrong argument
          Unexpected.new(object, defis, actual_call))
      end
    end
  end
end
