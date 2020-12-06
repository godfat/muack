
module Muack
  Definition  = Struct.new(:msg, :args, :returns,
                           :peek_args, :peek_return,
                           :target, :original_method, :visibility)
  ActualCall  = Struct.new(:msg, :args, :block)
  WithAnyArgs = Object.new
end
