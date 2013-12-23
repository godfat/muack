
module Muack
  Definition  = Class.new(Struct.new(:msg, :args, :block,
                                     :original_method,
                                     :peek_args, :peek_return))
  WithAnyArgs = Object.new
end
