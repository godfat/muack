
module Muack
  class Block < Struct.new(:block, :context)
    def initialize block, context=nil
      super
    end

    def call *args, &actual_block
      if context # ruby: no way to pass actual_block to instance_exec
        context.instance_exec(*args, &block)
      else
        block.call(*args, &actual_block)
      end
    end
  end
end
