module FastTCPN

  # Extends Token class to support time.
  # Stores also timestamp.
  class TimedToken < Token

    attr_accessor :timestamp

    # Create new token with specified +value+ and +timestamp+.
    def initialize(value, timestamp = 0)
      super value
      @timestamp = timestamp
    end

    # Create new token with the same value but new timestamp
    # Use it to quickly delay tokens while firing a transition
    # if token value change is not required.
    def with_timestamp(timestamp)
      self.class.new(value, timestamp)
    end

    def to_hash
      { val: value, ts: timestamp }
    end

  end
end
