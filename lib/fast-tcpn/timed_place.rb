module FastTCPN
  class TimedPlace < Place
    def initialize(name, keys = {})
      super
      @marking = TimedHashMarking.new keys
    end

    def next_time
      @marking.next_time
    end
  end
end
