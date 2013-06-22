
module Muack
  class Matcher < Struct.new(:message, :args)
    def match passed_arg
      !!passed_arg.public_send(message, *args)
    end

    def to_s
      "Muack.match(:#{message}, #{args.join(', ')})"
    end
    alias_method :inspect, :to_s
  end
end
