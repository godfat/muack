
module Muack
  Definition  = Struct.new(:msg, :args, :returns,
                           :peek_args, :peek_return,
                           :original_method, :visibility)
  WithAnyArgs = Object.new
end
