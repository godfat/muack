
module Muack
  class Failure < StandardError
    attr_reader :expected
    def build_expected obj, expected_defis
      @expected = expected_defis.uniq{ |d| [d.msg, d.args] }.map{ |defi|
                    "#{obj.inspect}.#{defi.msg}(" \
                    "#{defi.args.map(&:inspect).join(', ')})"
                  }.join("\n      or: ")
    end
  end

  class Unexpected < Failure
    attr_reader :was
    def initialize obj, expected_defis, actual_call
      args = actual_call.args.map(&:inspect)
      @was = "#{obj.inspect}.#{actual_call.msg}(#{args.join(', ')})"

      if expected_defis.empty?
        super("\nUnexpected call: #{was}")
      else
        build_expected(obj, expected_defis)
        super("\nExpected: #{expected}\n but was: #{was}")
      end
    end
  end

  class Expected < Failure
    attr_reader :expected_times, :actual_times
    def initialize obj, defi, expected_times, actual_times
      build_expected(obj, [defi])
      @expected_times = expected_times
      @actual_times   = actual_times

      super("\nExpected: #{expected}\n  called #{expected_times} times\n" \
            " but was #{actual_times} times.")
    end
  end
end
