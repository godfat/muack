
require 'muack/mock'
require 'muack/stub'
require 'muack/coat'
require 'muack/spy'
require 'muack/any_instance_of'

module Muack
  class Session
    attr_reader :data
    def initialize; @data = {}; end

    def mock obj; data["mk #{obj.__id__}"] ||= Mock.new(obj)      ; end
    def stub obj; data["sb #{obj.__id__}"] ||= Stub.new(obj)      ; end
    def coat obj; data["co #{obj.__id__}"] ||= Coat.new(obj)      ; end
    def spy  obj; data["sy #{obj.__id__}"] ||= Spy .new(stub(obj)); end

    def any_instance_of kls
      data["ai #{kls.__id__}"] ||= AnyInstanceOf.new(kls)
    end

    def verify obj=nil
      if obj
        with(obj, :[]).all?(&:__mock_verify)
      elsif RUBY_ENGINE == 'jruby'
        # Workaround weird error:
        # TypeError: Muack::Stub#to_ary should return Array
        data.each_value.all?{ |v| v.__mock_verify }
      else
        data.each_value.all?(&:__mock_verify)
      end
    end

    def reset obj=nil
      if obj
        with(obj, :delete).each(&:__mock_reset)
      else
        data.reverse_each{ |_, m| m.__mock_reset } # reverse_each_value?
        data.clear
      end
    end

    private
    def with obj, meth
      %w[mk sb co sy ai].map{ |k|
        data.__send__(meth, "#{k} #{obj.__id__}")
      }.compact
    end
  end
end
