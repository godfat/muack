
module Muack
  class AnyInstanceOf < Struct.new(:singleton_class)
    def inspect
      "Muack::API.any_instance_of(#{singleton_class})"
    end
  end
end
