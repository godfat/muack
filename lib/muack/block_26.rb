
module Muack
  class Block < Struct.new(:block, :context)
    def initialize block, context=nil
      super
    end

    def call(*args, &block)
      if context
        context.instance_exec(*args, &block)
      else
        block.call(*args, &block)
      end
    end
  end
end
