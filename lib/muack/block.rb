
module Muack
  class Block < Struct.new(:block, :context)
    def initialize block, context=nil
      super
    end

    def call(...)
      if context
        context.instance_exec(...)
      else
        block.call(...)
      end
    end
  end
end
