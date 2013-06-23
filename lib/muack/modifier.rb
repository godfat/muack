
require 'muack/definition'

module Muack
  class Modifier < Struct.new(:mock, :defi)
    # Public API
    def with_any_args
      defi.args = [WithAnyArgs]
      self
    end

    # Public API
    def times number
      (number - 1).times{ mock.__mock_defi_push(defi) }
      self
    end
  end
end
