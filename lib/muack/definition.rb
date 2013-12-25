
module Muack
  Definition  = Class.new(Struct.new(:msg, :args, :returns,
                                     :peek_args, :peek_return,
                                     :original_method))
  WithAnyArgs = Object.new
end
