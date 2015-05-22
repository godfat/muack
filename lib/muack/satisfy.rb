
module Muack
  class Satisfy < Struct.new(:api_args, :block)
    def initialize args=nil, &block
      super(args, block)
    end

    def match actual_arg
      !!block.call(actual_arg)
    end

    def | rhs; Satisfy::Disj.new(self, rhs); end
    def & rhs; Satisfy::Conj.new(self, rhs); end

    class Disj < Satisfy
      def initialize lhs, rhs
        @lhs, @rhs = lhs, rhs
      end

      def match actual_arg
        @lhs.match(actual_arg) || @rhs.match(actual_arg)
      end

      def to_s; "#{@lhs} | #{@rhs}"; end
      alias_method :inspect, :to_s
    end

    class Conj < Satisfy
      def initialize lhs, rhs
        @lhs, @rhs = lhs, rhs
      end

      def match actual_arg
        @lhs.match(actual_arg) && @rhs.match(actual_arg)
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
      super || [block || method(:match)]
    end
  end

  class IsA < Satisfy
    def initialize klass
      super([klass])
    end

    def match actual_arg
      actual_arg.kind_of?(api_args.first)
    end
  end

  class Anything < Satisfy
    def initialize
      super([])
    end

    def match _
      true
    end
  end

  class Match < Satisfy
    def initialize regexp
      super([regexp])
    end

    def match actual_arg
      api_args.first.match(actual_arg)
    end
  end

  class HashIncluding < Satisfy
    def initialize subset
      super([subset])
    end

    def match actual_arg, subset=api_args.first
      actual_arg.values_at(*subset.keys).zip(subset.values).all? do |(av, ev)|
        if ev.kind_of?(Satisfy)
          ev.match(av)
        elsif ev.kind_of?(Hash)
          match(av, ev)
        else
          ev == av
        end
      end
    end
  end

  class Including < Satisfy
    def initialize element
      super([element])
    end

    def match actual_arg
      actual_arg.include?(api_args.first)
    end
  end

  class Within < Satisfy
    def initialize range_or_array
      super([range_or_array])
    end

    def match actual_arg
      api_args.first.include?(actual_arg)
    end
  end

  class RespondTo < Satisfy
    def initialize *messages
      super(messages)
    end

    def match actual_arg
      api_args.all?{ |msg| actual_arg.respond_to?(msg) }
    end
  end
end
