
require 'muack/mock'
require 'muack/stub'
require 'muack/any_instance_of'

module Muack
  class Session < Hash
    def mock obj; self["mk #{obj.__id__}"] ||= Mock.new(obj); end
    def stub obj; self["sb #{obj.__id__}"] ||= Stub.new(obj); end

    def any_instance_of kls
      (@others ||= {})["ai #{kls.__id__}"] ||= AnyInstanceOf.new(kls)
    end

    def verify
      each_value.all?(&:__mock_verify)
    end

    def reset
      instance_variable_defined?(:@others) && @others.clear
      each_value(&:__mock_reset)
      clear
    end
  end
end
