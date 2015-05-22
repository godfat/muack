
module Muack
  Error = Class.new(NotImplementedError)
  class CannotFindInjectionName < Error
    def initialize t, msg
      super "\nCan't find a new method name for :#{msg}, tried #{t} times." \
            "\nSet ENV['MUACK_RECURSION_LEVEL'] to raise this limit."
    end
  end

  class StubHasNoTimes < Error
    def initialize obj, defi, times
      super "\nUse mocks if you want to specify times.\ne.g. "          \
            "mock(#{obj.inspect}).#{defi.msg}(#{defi.args.join(', ')})" \
            ".times(#{times})"
    end
  end

  class UnknownSpec < Error
    def initialize spec
      super "\nUnknown spec: #{spec.inspect}"
    end
  end
end
