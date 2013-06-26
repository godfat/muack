
require 'muack/mock'

module Muack
  class Spy < Mock
    def initialize stub
      super(stub.object)
      @secret = stub.__mock_disps.values.flatten # steal disps
    end

    # used for Muack::Session#verify
    def __mock_verify
      @secret.each{ |defi| __mock_dispatch(defi.msg, defi.args) }
      super # simulate dispatching before passing to mock to verify
    end

    # used for Muack::Session#reset, no need to do anything
    def __mock_reset
    end

    private
    def __mock_inject_method defi; end # no point to inject anything
  end
end
