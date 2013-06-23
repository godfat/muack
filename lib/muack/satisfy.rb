
module Muack
  class Satisfy < Struct.new(:block, :api_args)
    def match actual_arg
      !!block.call(actual_arg)
    end

    def to_s
      "Muack::API.#{api_name}(#{api_args.map(&:inspect).join(', ')})"
    end
    alias_method :inspect, :to_s

    def api_name
      self.class.name[/::(\w+)$/, 1].
        gsub(/([A-Z][a-z]*)+?(?=[A-Z][a-z]*)/, '\\1_').downcase
    end

    def api_args
      super || [block]
    end
  end

  class IsA < Satisfy
    def initialize klass
      super lambda{ |actual_arg| actual_arg.kind_of?(klass) }, [klass]
    end
  end

  class Anything < Satisfy
    def initialize
      super lambda{ |_| true }, []
    end
  end

  class Match < Satisfy
    def initialize regexp
      super lambda{ |actual_arg| regexp.match(actual_arg) }, [regexp]
    end
  end

  class HashIncluding < Satisfy
    def initialize hash
      super lambda{ |actual_arg|
        actual_arg.values_at(*hash.keys) == hash.values }, [hash]
    end
  end

  class Within < Satisfy
    def initialize range_or_array
      super lambda{ |actual_arg| range_or_array.include?(actual_arg) },
            [range_or_array]
    end
  end
end
