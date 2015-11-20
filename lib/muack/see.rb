
require 'muack/spy'

module Muack
  class See < Spy
    private
    def __mock_dispatch_spy
      @stub.__mock_disps.values.flatten.each do |defi|
        defis = __mock_defis[defi.msg]
        if defis && idx = __mock_find_checked_difi(defis, defi.args, :index)
          defis.delete_at(idx)
          __mock_disps_push(defi)
        end
      end
    end
  end
end
