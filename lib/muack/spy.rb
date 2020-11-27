
require 'muack/mock'

module Muack
  class Spy < Mock
    def initialize stub
      super(stub.object)
      @stub = stub
    end

    # used for Muack::Session#verify
    def __mock_verify
      __mock_dispatch_spy
      super
    end

    # used for Muack::Session#reset, but spies never leave any track
    def __mock_reset; end

    private
    def __mock_inject_method defi; end # spies don't leave any track

    # simulate dispatching before passing to mock to verify
    def __mock_dispatch_spy
      @stub.__mock_disps.values.flatten.each do |disp|
        next unless __mock_defis.key?(disp.msg) # ignore undefined spies

        defis = __mock_defis[disp.msg]
        if idx = __mock_find_checked_difi(defis, disp, :index)
          __mock_disps_push(defis.delete_at(idx)) # found, dispatch it
        elsif defis.empty? # show called candidates
          __mock_failed(disp)
        else # show expected candidates
          __mock_failed(disp, defis)
        end
      end
    end
  end
end
