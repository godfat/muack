
module Muack
  class Session
    attr_reader :mocks, :definitions, :dispatches
    def initialize
      @mocks, @definitions, @dispatches = [], [], []
    end

    def verify
      definitions == dispatches
    end
  end
end
