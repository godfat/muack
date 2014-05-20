
require 'muack/mock'

module Muack
  class Spy < Mock
    def initialize stub
      super(stub.object)
      @stub = stub
    end

    # used for Muack::Session#verify
    def __mock_verify
      @stub.__mock_disps.values.flatten.each do |defi|
        __mock_dispatch(defi.msg, defi.args) if __mock_defis.key?(defi.msg)
      end
      super # simulate dispatching before passing to mock to verify
    end

    # used for Muack::Session#reset, but spies never leave any track
    def __mock_reset; end

    private
    def __mock_inject_method defi; end # spies don't leave any track
  end
end
