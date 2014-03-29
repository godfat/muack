
require 'muack/mock'
require 'muack/stub'
require 'muack/spy'
require 'muack/any_instance_of'

module Muack
  class Session < Hash
    def mock obj; self["mk #{obj.__id__}"] ||= Mock.new(obj)      ; end
    def stub obj; self["sb #{obj.__id__}"] ||= Stub.new(obj)      ; end
    def spy  obj; self["sy #{obj.__id__}"] ||= Spy .new(stub(obj)); end

    def any_instance_of kls
      (@others ||= {})["ai #{kls.__id__}"] ||= AnyInstanceOf.new(kls)
    end

    def verify obj=nil
      if obj
        with(obj, :[]).all?(&:__mock_verify)
      else
        each_value.all?(&:__mock_verify)
      end
    end

    def reset obj=nil
      if obj
        with(obj, :delete).each(&:__mock_reset)
      else
        instance_variable_defined?(:@others) && @others.clear
        reverse_each{ |_, m| m.__mock_reset }
        clear
      end
    end

    private
    def with obj, meth
      %w[mk sb sy].map{ |k| __send__(meth, "#{k} #{obj.__id__}") }.compact
    end
  end
end
