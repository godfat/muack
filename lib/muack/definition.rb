
module Muack
  Definition  = Class.new(Struct.new(:msg, :args, :block, :original_method))
  WithAnyArgs = Object.new
end
