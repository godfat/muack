
require 'muack/test'

describe 'from README.md' do
  readme = File.read(
             "#{File.dirname(File.expand_path(__FILE__))}/../README.md")
  codes  = readme.scan(/``` ruby(.+?)```/m).map(&:first)

  after{ Muack.reset }

  Context = Module.new{
    include Muack::API

    def describe desc, &block
      @executor.describe(desc, &block)
      @executor.send(:execute_with_parent, @stat)
    end

    def results; @results ||= []; end
    def p res  ; results << res ; end

    def verify expects
      return if results.empty?
      results.zip(expects).each do |(res, exp)|
        next if exp == 'ok'
        if exp.start_with?('raise')
          res.should.kind_of? eval(exp.sub('raise', ''))
        else
          res.should.eq eval(exp)
        end
      end
    end
  }

  codes.each.with_index do |code, index|
    would 'pass from README.md #%02d' % index do
      executor, stat = Class.new(self.class){ init }, pork_stat
      context = Module.new do
        extend Context
        @executor, @stat = executor, stat
      end
      begin
        context.instance_eval(code, 'README.md', 0)
      rescue Muack::Failure => e
        context.p e
      end
      context.verify(code.scan(/# (.+)/).map(&:first))
    end
  end
end
