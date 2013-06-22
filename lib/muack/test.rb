
require 'bacon'
require 'muack'

Bacon.summary_on_exit
include Muack::API

module Kernel
  def eq? rhs
    self == rhs
  end
end
