
module Muack
  class AnyInstanceOf < Struct.new(:klass)
    def singleton_class
      klass
    end
  end
end
