
require 'bacon'
require 'muack'

Bacon.summary_on_exit

module Kernel
  def eq? rhs
    self == rhs
  end
end
