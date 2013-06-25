
module Muack
  class Session < Hash
    def verify
      each_value.all?(&:__mock_verify)
    end

    def reset
      each_value(&:__mock_reset)
      clear
    end
  end
end
