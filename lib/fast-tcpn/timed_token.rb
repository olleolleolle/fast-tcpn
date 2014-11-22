module FastTCPN

  class TimedToken < Token

    attr_accessor :timestamp

    def initialize(value, timestamp = 0)
      super value
      @timestamp = timestamp
    end

    def with_timestamp(timestamp)
      self.class.new(value, timestamp)
    end

  end
end
