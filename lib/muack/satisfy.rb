
require 'muack/error'

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

  class Anything < Satisfy
    def initialize
      super([])
    end

    def match _
      true
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

  class Matching < Satisfy
    def initialize regexp
      super([regexp])
    end

    def match actual_arg
      api_args.first.match(actual_arg)
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

  class RespondingTo < Satisfy
    def initialize *messages
      super(messages)
    end

    def match actual_arg
      api_args.all?{ |msg| actual_arg.respond_to?(msg) }
    end
  end

  class MatchSpec < Satisfy
    def initialize spec
      super([spec])
    end

    def match actual_arg, spec=api_args.first
      case spec
      when Hash
        match_hash(actual_arg, spec)
      when Array
        match_array(actual_arg, spec)
      else
        raise UnknownSpec.new(spec)
      end
    end

    private
    def match_hash actual_arg, spec
      (spec.keys | actual_arg.keys).all? do |key|
        match_value(actual_arg[key], spec[key])
      end
    end

    def match_array actual_arg, spec
      spec.zip(actual_arg).all? do |(ev, av)|
        match_value(av, ev)
      end
    end

    def match_value av, ev
      case ev
      when Satisfy
        ev.match(av)
      when Hash
        match_hash(av, ev)
      when Array
        match_array(av, ev)
      else
        ev == av
      end
    end
  end

  class Having < MatchSpec
    def initialize subset
      super(subset)
    end

    private
    def match_hash actual_arg, subset
      subset.each_key.all? do |key|
        match_value(actual_arg[key], subset[key])
      end
    end
  end

  class Allowing < MatchSpec
    def initialize superset
      super(superset)
    end

    private
    def match_hash actual_arg, superset
      actual_arg.each_key.all? do |key|
        match_value(actual_arg[key], superset[key])
      end
    end
  end
end
