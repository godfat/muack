
module Muack
  Error = Class.new(NotImplementedError)
  class CannotFindInjectionName < Error
    def initialize t, msg
      super "\nCan't find a new method name for :#{msg}, tried #{t} times." \
            "\nSet ENV['MUACK_RECURSION_LEVEL'] to raise this limit."
    end
  end
end
