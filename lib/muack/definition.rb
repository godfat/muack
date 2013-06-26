
module Muack
  Definition  = Class.new(Struct.new(:msg, :args, :block,
                                     :original_method, :proxy))
  WithAnyArgs = Object.new
end
