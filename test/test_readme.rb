
require 'bacon'
require 'muack'

include Muack::API

describe 'Hello' do
  before{ Muack.reset  }
  after { Muack.verify }

  should 'say world!' do
    str = 'Hello'
    mock(str).say('!'){ |arg| "World#{arg}" }
    str.say('!').should.equal 'World!'
  end
end
