
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
      left = @stub.__mock_disps.values.flatten.map do |disp|
        if (defis = __mock_defis[disp.msg]) && defis && defis.any?
          if idx = __mock_find_checked_difi(defis, disp.args, :index)
            defis.delete_at(idx) # found, dispatch it
            __mock_disps_push(disp)
            nil
          else
            disp # we might be interested if defis aren't drained in the end
          end
        end
      end

      if __mock_defis.values.any?(&:any?) # now we're interested...
        # we do a regular dispatch in this case to make better error messages
        # because this way it could compare actual calls with expectation
        left.each{ |disp| disp && __mock_dispatch(disp.msg, disp.args) }
      end
    end
  end
end
