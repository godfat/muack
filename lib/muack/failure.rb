
module Muack
  class Failure < Exception
    attr_reader :expected
    def build_expected obj, defis
      @expected = defis.uniq{ |defi| [defi.msg, defi.args] }.map{ |defi|
                    "#{obj.inspect}.#{defi.msg}(" \
                    "#{defi.args.map(&:inspect).join(', ')})"
                  }.join("\n      or: ")
    end
  end

  class Unexpected < Failure
    attr_reader :was
    def initialize obj, expected_defis, msg, args
      build_expected(obj, expected_defis)
      @was      = "#{obj.inspect}.#{msg}(" \
                  "#{args.map(&:inspect).join(', ')})"

      super("\nExpected: #{expected}\n but was: #{was}")
    end
  end

  class Expected < Failure
    attr_reader :expected_times, :actual_times
    def initialize obj, expected_defis, expected_times, actual_times
      build_expected(obj, expected_defis)
      @expected_times = expected_times
      @actual_times   = actual_times

      super("\nExpected: #{expected}\n  called #{expected_times} times\n" \
            " but was #{actual_times} times.")
    end
  end
end
