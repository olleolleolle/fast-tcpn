module FastTCPN
  # This class extends Place class to support time and timed tokens.
  # TimedHashMarking class is used to store tokens.
  #
  # It is however slower in simulation than not-timed version, so
  # use with care when you really need it.
  class TimedPlace < Place
    # Create new timed place.
    # +name+ is unique identifier of the place
    # +keys+ are used to efficiently access marking in this place
    # +net+ is TCPN class object, used to enable callbacks
    def initialize(name, keys = {}, net = nil)
      super
      @marking = TimedHashMarking.new keys
      @clock = 0
    end

    # returns next timestamp that will cause more tokens
    # to be available in this place
    def next_time
      @marking.next_time
    end

    # set current time for this place 
    # (will move tokens from waiting to active state).
    # Putting clock back will cause error.
    def time=(val)
      @clock = val
      @marking.time = val
    end

    # Adds token with specified timestamp to the place.
    # Any callbacks defined for places will be fired.
    def add(token, timestamp = nil)
      @net.call_callbacks(:place, :add, Event.new(@name, [token], @net)) unless @net.nil?
      if timestamp.nil?
        @marking.add token
      else
        @marking.add token, timestamp
      end
    end

  end
end
