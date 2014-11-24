module FastTCPN

  class TimedHashMarking < HashMarking
    InvalidTime = Class.new RuntimeError

    attr_reader :time, :next_time

    def initialize(*)
      super
      @time = 0
      @waiting = {}
      @next_time = 0
    end

    def add(object, timestamp = @time)
      if object.instance_of? Hash
        timestamp = object[:ts]
        object = object[:val]
      end
      token = prepare_token(object, timestamp)
      timestamp = token.timestamp
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
        if timestamp > @time
          @next_time = timestamp
          break
        end
        @waiting[timestamp].each { |token| add_token token }
        @waiting.delete timestamp
      end
      @next_time = 0 if @waiting.empty?
      @time
    end

    private

    def prepare_token(object, timestamp = 0)
      if object.instance_of? token_type
        clone object
      else
        token_type.new clone(object), timestamp
      end
    end

    def token_type
      TimedToken
    end

    def add_to_waiting(token)
      @waiting[token.timestamp] ||= []
      @waiting[token.timestamp] << token
      if @next_time == 0 || token.timestamp < @next_time
        @next_time = token.timestamp
      end
    end

  end

end
