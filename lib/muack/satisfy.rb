
module Muack
  class Satisfy < Struct.new(:block, :api_args)
    def match actual_arg
      !!block.call(actual_arg)
    end

    def | rhs; Satisfy::Disj.new(self, rhs); end
    def & rhs; Satisfy::Conj.new(self, rhs); end

    class Disj < Satisfy
      def initialize lhs, rhs
        @lhs, @rhs = lhs, rhs
        super(lambda{ |actual_arg| lhs.match(actual_arg) ||
                                   rhs.match(actual_arg) })
      end

      def to_s; "#{@lhs} | #{@rhs}"; end
      alias_method :inspect, :to_s
    end

    class Conj < Satisfy
      def initialize lhs, rhs
        @lhs, @rhs = lhs, rhs
        super(lambda{ |actual_arg| lhs.match(actual_arg) &&
                                   rhs.match(actual_arg) })
      end

      def to_s; "#{@lhs} & #{@rhs}"; end
      alias_method :inspect, :to_s
    end

    def to_s
      "Muack::API.#{api_name}(#{api_args.map(&:inspect).join(', ')})"
    end
    alias_method :inspect, :to_s

    def api_name
      (self.class.name || 'Unknown')[/(::)*(\w+)$/, 2].
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

  class Including < Satisfy
    def initialize element
      super lambda{ |actual_arg|
        actual_arg.include?(element) }, [element]
    end
  end

  class Within < Satisfy
    def initialize range_or_array
      super lambda{ |actual_arg| range_or_array.include?(actual_arg) },
            [range_or_array]
    end
  end

  class RespondTo < Satisfy
    def initialize *messages
      super lambda{ |actual_arg|
        messages.all?{ |msg| actual_arg.respond_to?(msg) } }, messages
    end
  end
end
