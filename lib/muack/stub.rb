
require 'muack/mock'

module Muack
  class Stub < Mock
    def __mock_definitions _=nil; []; end
    def __mock_dispatches  _=nil; []; end
  end
end
