module FastTCPN
  class TimedPlace < Place
    def initialize(name, keys = {})
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
      if timestamp.nil?
        @marking.add token
      else
        @marking.add token, timestamp
      end
    end

  end
end
