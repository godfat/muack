
require 'muack/definition'

module Muack
  class Modifier < Struct.new(:defi)
    # Public API
    def with_any_args
      defi.args = [WithAnyArgs]
      self
    end

    # Public API
    # TODO: test
    def times number
      __mock_definitions.concat([__mock_definitions.last] * number)
      self
    end
  end
end
