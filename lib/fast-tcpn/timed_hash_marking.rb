module FastTCPN

  class TimedHashMarking < HashMarking
    InvalidTime = Class.new RuntimeError

    attr_reader :time

    def initialize(*)
      super
      @time = 0
      @waiting = {}
    end

    def add(object, timestamp = @time)
      token = prepare_token(object, timestamp)
      if timestamp > @time
        add_to_waiting token
      else
        add_token token
      end
    end

    def time=(time)
      if time < @time
        raise InvalidTime.new("You are trying to put back clock from #{@time} back to #{time}")
      end
      @time = time
      @waiting.keys.sort.each do |timestamp|
        break if timestamp > @time
        @waiting[timestamp].each { |token| add_token token }
      end
      @time
    end

    private

    def prepare_token(object, timestamp)
      if object.instance_of? TimedToken
        clone object
      else
        TimedToken.new clone(object), timestamp
      end
    end

    def token_type
      TimedToken
    end

    def add_to_waiting(token)
      @waiting[token.timestamp] ||= []
      @waiting[token.timestamp] << token
    end
  end

end
