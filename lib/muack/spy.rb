
require 'muack/mock'

module Muack
  class Spy < Mock
    def initialize stub
      super(stub.object)
      self.__mock_disps = stub.__mock_disps.dup # steal disps
    end

    # used for Muack::Session#verify
    def __mock_verify
      __mock_disps.values.flatten.each{ |defi|
        __mock_dispatch(defi.msg, defi.args) } # simulate dispatching
      super
    end

    # used for Muack::Session#reset, no need to do anything
    def __mock_reset
    end

    private
    def __mock_inject_method defi; end # no point to inject anything
    def __mock_disps_push    defi; end # freeze __mock_disps
  end
end
