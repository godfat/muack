
module Muack
  Failure = Class.new(Exception)

  class Unexpected < Failure
    attr_reader :expected, :was
    def initialize obj, defi, args
      @expected = "#{obj.inspect}.#{defi.message}(" \
                  "#{defi.args.map(&:inspect).join(', ')})"
      @was      = "#{obj.inspect}.#{defi.message}(" \
                  "#{args.map(&:inspect).join(', ')})"
      super("\nExpected: #{expected}\n but was: #{was}")
    end
  end

  class Expected < Failure
    attr_reader :expected, :expected_times, :actual_times
    def initialize obj, defi, expected_times, actual_times
      @expected = "#{obj.inspect}.#{defi.message}(" \
                  "#{defi.args.map(&:inspect).join(', ')})"
      @expected_times = expected_times
      @actual_times   = actual_times

      super("\nExpected: #{expected}\n  called #{expected_times} times\n" \
            " but was #{actual_times} times.")
    end
  end
end
