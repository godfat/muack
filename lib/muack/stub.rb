
require 'muack/mock'

module Muack
  class Stub < Mock
    def __mock_definitions _; end
    def __mock_dispatches  _; end
  end
end
