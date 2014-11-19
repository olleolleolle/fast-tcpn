module FastTCPN

  class TimedToken < Token

    attr_accessor :timestamp

    def initialize(value, timestamp = 0)
      super value
      @timestamp = timestamp
    end

  end
end
