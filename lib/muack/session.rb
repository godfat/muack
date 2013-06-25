
require 'muack/mock'
require 'muack/stub'
require 'muack/proxy'
require 'muack/any_instance_of'

module Muack
  class Session < Hash
    def mock       obj; self["mk #{obj.__id__}"] ||= Mock     .new(obj); end
    def stub       obj; self["sb #{obj.__id__}"] ||= Stub     .new(obj); end
    def mock_proxy obj; self["mp #{obj.__id__}"] ||= MockProxy.new(obj); end
    def stub_proxy obj; self["sp #{obj.__id__}"] ||= StubProxy.new(obj); end

    def any_instance_of klass
      (@any_instance_of ||= {})[klass.__id__] ||= AnyInstanceOf.new(klass)
    end

    def verify
      each_value.all?(&:__mock_verify)
    end

    def reset
      each_value(&:__mock_reset)
      clear
    end
  end
end
