
require 'muack/mock'

module Muack
  class Stub < Mock
    def __mock_verify; true; end
  end
end
