
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
      if number >= 1
        (number - 1).times{ mock.__mock_defis_push(defi) }
      elsif number == 0
        mock.__mock_ignore(mock.__mock_defis_pop(defi))
      else
        raise "What would you expect from calling a method #{number} times?"
      end
      self
    end

    # Public API
    def object
      mock.object
    end
  end
end
