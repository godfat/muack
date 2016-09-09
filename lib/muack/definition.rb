
module Muack
  Definition  = Struct.new(:msg, :args, :returns,
                           :peek_args, :peek_return,
                           :original_method)
  WithAnyArgs = Object.new
end
