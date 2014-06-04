
module Muack
  class AnyInstanceOf < Struct.new(:singleton_class)
    def inspect
      "Muack::API.any_instance_of(#{singleton_class})"
    end

    # dummies for Muack::Session
    def __mock_verify; true; end
    def __mock_reset ;     ; end
  end
end
