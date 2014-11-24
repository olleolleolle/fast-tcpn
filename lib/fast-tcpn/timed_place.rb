module FastTCPN
  class TimedPlace < Place
    def initialize(name, keys = {}, net = nil)
      super
      @marking = TimedHashMarking.new keys
    end

    def next_time
      @marking.next_time
    end

    def time=(val)
      @marking.time = val
    end

    def add(token, timestamp = nil)
      @net.call_callbacks(:place, :add, Event.new(@name, [token])) unless @net.nil?
      if timestamp.nil?
        @marking.add token
      else
        @marking.add token, timestamp
      end
    end

  end
end
