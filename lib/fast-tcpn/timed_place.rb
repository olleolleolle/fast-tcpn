module FastTCPN
  class TimedPlace < Place
    def initialize(name, keys = {})
      super
      @marking = TimedHashMarking.new keys
    end
  end
end
