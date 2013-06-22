
module Muack
  class Satisfy < Struct.new(:block)
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

  class IsA < Satisfy
    def initialize klass
      @api_args = [klass]
      super lambda{ |actual_arg| actual_arg.kind_of?(klass) }
    end
  end

  class Within < Satisfy
    def initialize range_or_array
      @api_args = [range_or_array]
      super lambda{ |actual_arg| range_or_array.include?(actual_arg) }
    end
  end

  class Anything < Satisfy
    def initialize
      @api_args = []
      super lambda{ |_| true }
    end
  end

  class Match < Satisfy
    def initialize regexp
      @api_args = [regexp]
      super lambda{ |actual_arg| regexp.match(actual_arg) }
    end
  end
end
