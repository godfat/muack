
module Muack
  class Matcher < Struct.new(:block)
    def match actual_arg
      !!block.call(actual_arg)
    end

    def to_s
      "Muack::API.#{api_name}(#{api_args.join(', ')})"
    end
    alias_method :inspect, :to_s

    def api_name
      self.class.name[/::(\w+)$/, 1].
        gsub(/([A-Z][a-z]*)+?(?=[A-Z][a-z]*)/, '\\1_').downcase
    end

    def api_args
      @api_args || [block]
    end
  end

  class IsA < Matcher
    def initialize klass
      @api_args = [klass]
      super lambda{|actual_arg| actual_arg.kind_of?(klass)}
    end
  end

  class Within < Matcher
    def initialize range_or_array_or_hash
      @api_args = [range_or_array_or_hash]
      super lambda{|actual_arg| range_or_array_or_hash.include?(actual_arg)}
    end
  end
end
