
module Muack
  class Unexpected < Exception
    attr_reader :expected, :was
    def initialize obj, defi, args
      @expected = "#{obj.inspect}.#{defi.message}(" \
                  "#{defi.args.map(&:inspect).join(', ')})"
      @was      = "#{obj.inspect}.#{defi.message}(" \
                  "#{args.map(&:inspect).join(', ')})"
      super("\nExpected: #{expected}\n but was: #{was})")
    end
  end
end
