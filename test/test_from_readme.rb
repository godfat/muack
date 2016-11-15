
require 'muack/test'

describe 'from README.md' do
  readme = File.read("#{__dir__}/../README.md")
  codes  = readme.scan(/``` ruby(.+?)```/m).map(&:first)

  after{ Muack.reset }

  Context = Module.new{
    include Muack::API

    def describe desc, &block
      @suite.describe(desc, &block)
      Pork::Executor.execute(:stat => @stat, :suite => @suite)
    end

    def results; @results ||= []; end
    def p res  ; results << res ; end

    def verify expects
      results.zip(expects).each do |(res, exp)|
        next if exp == 'ok'
        if exp.start_with?('raise')
          res.should.kind_of? eval(exp.sub('raise', ''))
        else
          res.should.eq instance_eval(exp)
        end
      end
    end
  }

  codes.each.with_index do |code, index|
    would 'pass from README.md #%02d' % index do
      suite, stat = Class.new(self.class){ init }, pork_stat
      context = Module.new do
        extend Context
        @suite, @stat = suite, stat
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
